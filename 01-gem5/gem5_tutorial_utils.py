"""Focused parsing and plotting helpers for the GEM5 tutorial notebooks."""

from __future__ import annotations

from collections import OrderedDict
from pathlib import Path
import contextlib
import importlib.util
import io
import re
import sqlite3

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


MEMCPY_RESULT_RE = re.compile(
    r"MEMCPY_RESULT\s+bytes=(?P<bytes>\d+)\s+cycles=(?P<cycles>\d+)\s+"
    r"payload_mib_s=(?P<payload_mib_s>[0-9.]+)\s+"
    r"traffic_mib_s=(?P<traffic_mib_s>[0-9.]+)\s+"
    r"checksum=(?P<checksum>0x[0-9a-fA-F]+)"
)

STAGE_COLUMNS = [
    "AtFetch",
    "AtDecode",
    "AtRename",
    "AtDispQue",
    "AtIssueQue",
    "AtIssueArb",
    "AtIssueReadReg",
    "AtFU",
    "AtBypassVal",
    "AtWriteVal",
    "AtCommit",
]

STAGE_LABELS = [
    "fetch",
    "decode",
    "rename",
    "dispatch",
    "issue-q",
    "issue-arb",
    "read-reg",
    "execute",
    "bypass",
    "writeback",
    "commit",
]

TOPDOWN_LEVEL1 = OrderedDict(
    [
        ("Retiring", ["NoStall"]),
        (
            "Frontend",
            [
                "IcacheStall",
                "ITlbStall",
                "FetchBufferInvalid",
                "OtherFetchStall",
                "FragStall",
            ],
        ),
        (
            "Bad speculation",
            [
                "BpStall",
                "SquashStall",
                "InstMisPred",
                "InstSquashed",
                "CommitSquash",
            ],
        ),
        (
            "Memory",
            [
                "DTlbStall",
                "LoadL1Bound",
                "LoadL2Bound",
                "LoadL3Bound",
                "LoadMemBound",
                "StoreL1Bound",
                "StoreL2Bound",
                "StoreL3Bound",
                "StoreMemBound",
                "MemSquashed",
                "MemNotReady",
                "MemCommitRateLimit",
                "OtherMemStall",
                "LoadTLBStall",
                "LoadL1Stall",
                "LoadL2Stall",
                "LoadL3Stall",
                "LoadMemStall",
                "StoreStall",
                "LoadMSHRReplayStall",
            ],
        ),
        (
            "Core/other",
            [
                "LongExecute",
                "ScalarLongExecute",
                "VectorLongExecute",
                "InstNotReady",
                "ReadyButNotIssued",
                "ScalarReadyButNotIssued",
                "VectorReadyButNotIssued",
                "SerializeStall",
                "IntStall",
                "TrapStall",
                "Atomic",
                "AtomicStall",
                "ResumeUnblock",
                "OtherCoreStall",
                "OtherStall",
            ],
        ),
    ]
)

TOPDOWN_MEMORY = OrderedDict(
    [
        ("L1", ["LoadL1Bound", "StoreL1Bound", "LoadL1Stall"]),
        ("L2", ["LoadL2Bound", "StoreL2Bound", "LoadL2Stall"]),
        ("L3", ["LoadL3Bound", "StoreL3Bound", "LoadL3Stall"]),
        ("DRAM", ["LoadMemBound", "StoreMemBound", "LoadMemStall"]),
        ("TLB", ["LoadTLBStall", "DTlbStall"]),
        (
            "Waiting/other",
            [
                "MemNotReady",
                "MemNotReadyStall",
                "MemCommitRateLimit",
                "MemSquashed",
                "OtherMemStall",
                "StoreStall",
                "LoadMSHRReplayStall",
            ],
        ),
    ]
)


def _path(path: str | Path) -> Path:
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(path)
    return path


def parse_memcpy_log(path: str | Path) -> dict:
    """Parse the last MEMCPY_RESULT line from a GEM5 run log."""
    text = _path(path).read_text(errors="replace")
    matches = list(MEMCPY_RESULT_RE.finditer(text))
    if not matches:
        raise ValueError(f"No MEMCPY_RESULT line found in {path}")
    result = matches[-1].groupdict()
    for key in ("bytes", "cycles"):
        result[key] = int(result[key])
    for key in ("payload_mib_s", "traffic_mib_s"):
        result[key] = float(result[key])
    return result


def memcpy_results(logs: dict[str, str | Path]) -> pd.DataFrame:
    rows = []
    for label, log in logs.items():
        row = parse_memcpy_log(log)
        row["configuration"] = label
        rows.append(row)
    frame = pd.DataFrame(rows).set_index("configuration")
    baseline = frame.iloc[0]["payload_mib_s"]
    frame["speedup"] = frame["payload_mib_s"] / baseline
    return frame


def plot_memcpy_bandwidth(
    logs: dict[str, str | Path], title: str = "Memcpy performance"
) -> tuple[plt.Figure, pd.DataFrame]:
    frame = memcpy_results(logs)
    colors = ["#5f6368", "#1a73e8", "#e8710a", "#188038"][: len(frame)]
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.2), constrained_layout=True)

    bars = axes[0].bar(frame.index, frame["payload_mib_s"], color=colors)
    axes[0].bar_label(bars, fmt="%.1f", padding=3)
    axes[0].set_ylabel("Payload bandwidth (MiB/s)")
    axes[0].set_title(title)
    axes[0].grid(axis="y", alpha=0.25)

    bars = axes[1].bar(frame.index, frame["speedup"], color=colors)
    axes[1].bar_label(
        bars, labels=[f"{value:.2f}x" for value in frame["speedup"]], padding=3
    )
    axes[1].axhline(1.0, color="#5f6368", linewidth=1)
    axes[1].set_ylabel("Speedup over first configuration")
    axes[1].set_title("Relative improvement")
    axes[1].grid(axis="y", alpha=0.25)

    for axis in axes:
        axis.tick_params(axis="x", rotation=12)
        axis.spines[["top", "right"]].set_visible(False)
    return fig, frame


def _first_csv_row(path: str | Path) -> pd.Series:
    frame = pd.read_csv(_path(path))
    if frame.empty:
        raise ValueError(f"No rows in {path}")
    return frame.iloc[0]


def _sum_columns(row: pd.Series, names: list[str]) -> float:
    return float(sum(float(row.get(name, 0) or 0) for name in names))


def topdown_breakdown(path: str | Path) -> tuple[pd.Series, pd.Series]:
    row = _first_csv_row(path)
    level1 = pd.Series(
        {name: _sum_columns(row, columns) for name, columns in TOPDOWN_LEVEL1.items()},
        dtype=float,
    )
    memory = pd.Series(
        {name: _sum_columns(row, columns) for name, columns in TOPDOWN_MEMORY.items()},
        dtype=float,
    )
    level1 = level1 / level1.sum() * 100.0
    if memory.sum() > 0:
        memory = memory / memory.sum() * 100.0
    return level1, memory


def _stacked_bar(axis, values: pd.Series, title: str) -> None:
    palette = ["#188038", "#1a73e8", "#d93025", "#e8710a", "#5f6368", "#9334e6"]
    left = 0.0
    for (label, value), color in zip(values.items(), palette):
        axis.barh([0], [value], left=left, color=color, label=label)
        if value >= 7:
            axis.text(
                left + value / 2,
                0,
                f"{value:.1f}%",
                ha="center",
                va="center",
                color="white",
            )
        left += value
    axis.set_xlim(0, 100)
    axis.set_yticks([])
    axis.set_xlabel("Share of classified cycles (%)")
    axis.set_title(title)
    axis.legend(loc="upper center", bbox_to_anchor=(0.5, -0.25), ncol=3, frameon=False)
    axis.spines[["top", "right", "left"]].set_visible(False)


def plot_topdown(path: str | Path) -> tuple[plt.Figure, tuple[pd.Series, pd.Series]]:
    level1, memory = topdown_breakdown(path)
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 5.8), constrained_layout=True)
    _stacked_bar(axes[0], level1, "Top-Down: coarse bottleneck classification")
    _stacked_bar(axes[1], memory, "Memory-bound cycles: where time is spent")
    return fig, (level1, memory)


def cpu_clock_period(stats_path: str | Path) -> int:
    """Read the CPU clock period from GEM5 stats instead of assuming 333."""
    for line in _path(stats_path).read_text(errors="replace").splitlines():
        if line.startswith("system.cpu_clk_domain.clock"):
            return int(line.split()[1])
    raise ValueError(f"CPU clock period not found in {stats_path}")


def lifetime_frame(
    db_path: str | Path,
    start_pc: int | None = None,
    end_pc: int | None = None,
    start_cycle: int | None = None,
    end_cycle: int | None = None,
    period: int = 333,
    limit: int | None = None,
    offset: int = 0,
) -> pd.DataFrame:
    where = ["AtCommit != 0"]
    params: list[int] = []
    if start_pc is not None:
        where.append("PC >= ?")
        params.append(start_pc)
    if end_pc is not None:
        where.append("PC < ?")
        params.append(end_pc)
    if start_cycle is not None:
        where.append("AtCommit >= ?")
        params.append(int(start_cycle * period))
    if end_cycle is not None and end_cycle >= 0:
        where.append("AtCommit <= ?")
        params.append(int(end_cycle * period))

    query = "SELECT * FROM LifeTimeCommitTrace WHERE " + " AND ".join(where)
    query += " ORDER BY ID"
    if limit is not None:
        query += " LIMIT ?"
        params.append(limit)
    elif offset:
        query += " LIMIT -1"
    if offset:
        query += " OFFSET ?"
        params.append(offset)
    with sqlite3.connect(_path(db_path)) as connection:
        return pd.read_sql_query(query, connection, params=params)


def _clock_analysis_module(path: str | Path):
    path = _path(path)
    spec = importlib.util.spec_from_file_location("gem5_clock_analysis", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _hot_blocks(
    db_path: str | Path, start_pc: int, end_pc: int
):
    frame = lifetime_frame(db_path, start_pc=start_pc, end_pc=end_pc)
    if frame.empty:
        raise ValueError("No PerfCCT rows found in the requested PC range")
    module = _clock_analysis_module(Path(__file__).resolve().parents[1] / "GEM5/util/ClockAnalysis.py")
    records = [(int(row.PC), str(row.DisAsm)) for row in frame.itertuples()]
    with contextlib.redirect_stderr(io.StringIO()):
        blocks, _ = module.ExtractBasicBlocks(records)
    return frame, blocks


def hot_loop_report(
    db_path: str | Path, start_pc: int, end_pc: int, top: int = 5
) -> pd.DataFrame:
    """Use ClockAnalysis basic-block reconstruction over the complete trace."""
    _, blocks = _hot_blocks(db_path, start_pc, end_pc)
    rows = []
    for rank, (block, count) in enumerate(blocks.most_common(top), start=1):
        rows.append(
            {
                "rank": rank,
                "count": count,
                "instructions": len(block),
                "start_pc": block[0][0],
                "end_pc": block[-1][0],
                "branch": block[-1][1],
            }
        )
    return pd.DataFrame(rows)


def hot_window(
    db_path: str | Path,
    start_pc: int,
    end_pc: int,
    period: int = 333,
    iteration: int = 64,
) -> tuple[int, int]:
    """Return a cycle window containing one complete occurrence of the hot block."""
    selected = _hot_block_occurrence(
        db_path, start_pc, end_pc, iteration=iteration
    )
    start = max(0, int(selected["AtCommit"].min() // period) - 1)
    end = int(np.ceil(selected["AtCommit"].max() / period)) + 1
    return start, end


def _hot_block_occurrence(
    db_path: str | Path,
    start_pc: int,
    end_pc: int,
    iteration: int = 64,
) -> pd.DataFrame:
    """Locate one complete dynamic occurrence of the most common basic block."""
    frame, blocks = _hot_blocks(db_path, start_pc, end_pc)
    block, count = blocks.most_common(1)[0]
    occurrence = min(max(iteration, 0), max(count - 1, 0))
    block_pcs = [pc for pc, _ in block]
    pcs = frame["PC"].astype(int).tolist()
    block_start = None
    seen = 0
    for index in range(len(pcs) - len(block_pcs) + 1):
        if pcs[index : index + len(block_pcs)] == block_pcs:
            if seen == occurrence:
                block_start = index
                break
            seen += 1
    if block_start is None:
        raise ValueError("Could not locate a complete hot-loop occurrence")
    return frame.iloc[block_start : block_start + len(block)].copy()


def hot_loop_ids(
    db_path: str | Path,
    start_pc: int,
    end_pc: int,
    iteration: int = 64,
) -> list[int]:
    """Return dynamic instruction IDs for one complete hot-loop occurrence."""
    selected = _hot_block_occurrence(
        db_path, start_pc, end_pc, iteration=iteration
    )
    return selected["ID"].astype(int).tolist()


def plot_perfcct_timeline(
    db_path: str | Path,
    start_pc: int,
    end_pc: int,
    period: int = 333,
    start_cycle: int | None = None,
    end_cycle: int | None = None,
    instructions: int | None = None,
    instruction_ids: list[int] | None = None,
    iteration: int = 64,
) -> tuple[plt.Figure, pd.DataFrame]:
    """Plot one instruction lifetime window.

    With no explicit bounds, select one occurrence of the most common basic
    block. This keeps the notebook call focused on the timeline itself.
    """
    select_hot_loop = (
        start_cycle is None
        and end_cycle is None
        and instructions is None
        and instruction_ids is None
    )
    if select_hot_loop:
        frame = _hot_block_occurrence(
            db_path, start_pc, end_pc, iteration=iteration
        )
    else:
        frame = lifetime_frame(
            db_path,
            start_pc=start_pc,
            end_pc=end_pc,
            start_cycle=start_cycle,
            end_cycle=end_cycle,
            period=period,
            limit=instructions,
        ).copy()
        if instruction_ids is not None:
            frame = frame[frame["ID"].isin(instruction_ids)].copy()
    if frame.empty:
        raise ValueError("No PerfCCT rows found in the requested PC range")

    active_stage_indices = [
        index
        for index, column in enumerate(STAGE_COLUMNS)
        if frame[column].gt(0).any()
    ]
    if not active_stage_indices:
        raise ValueError("No recorded pipeline stages found in the selected rows")
    stage_columns = [STAGE_COLUMNS[index] for index in active_stage_indices]
    stage_labels = [STAGE_LABELS[index] for index in active_stage_indices]
    if "AtDispQue" not in stage_columns:
        rename_index = stage_columns.index("AtRename")
        stage_labels[rename_index] = "rename/dispatch"

    raw_stages = frame[stage_columns].to_numpy(dtype=float)
    positive = raw_stages[raw_stages > 0]
    origin = positive.min() / period
    stages = raw_stages / period - origin
    colors = plt.get_cmap("tab20").colors
    fig_height = max(5.0, len(frame) * 0.24)
    fig, axis = plt.subplots(figsize=(12.0, fig_height), constrained_layout=True)

    for row_index, stage_ticks in enumerate(stages):
        valid = np.flatnonzero(raw_stages[row_index] > 0)
        for left, right in zip(valid, valid[1:]):
            begin = stage_ticks[left]
            finish = stage_ticks[right]
            if finish <= begin:
                continue
            axis.barh(
                row_index,
                finish - begin,
                left=begin,
                height=0.72,
                color=colors[active_stage_indices[left]],
            )

    labels = [f"0x{int(pc):x}  {asm}" for pc, asm in zip(frame["PC"], frame["DisAsm"])]
    axis.set_yticks(range(len(frame)), labels=labels)
    axis.invert_yaxis()
    axis.set_xlabel("")
    axis.set_ylabel("Dynamic instructions")
    axis.set_title("PerfCCT instruction timeline")
    axis.grid(axis="x", alpha=0.2)
    axis.spines[["top", "right"]].set_visible(False)

    handles = [
        plt.Line2D(
            [0], [0], color=colors[index], linewidth=6, label=label
        )
        for index, label in zip(active_stage_indices[:-1], stage_labels[:-1])
    ]
    axis.legend(
        handles=handles,
        loc="upper center",
        bbox_to_anchor=(0.5, -0.06),
        ncol=5,
        frameon=False,
    )
    return fig, frame


def clock_analysis_perfcct(
    clock_analysis_path: str | Path,
    db_path: str | Path,
    start_clock: int,
    end_clock: int,
    start_pc: int,
    end_pc: int,
    period: int = 333,
    attention_pcs: tuple[int, ...] = (),
) -> None:
    """Run ClockAnalysis.py's per-instruction printer inside a notebook."""
    module = _clock_analysis_module(clock_analysis_path)
    module.period = period
    inst_info, inst_pos, _ = module.ReadDB(
        str(_path(db_path)), start_clock, end_clock, False, False
    )
    normalized = [(hex(int(pc)), asm) for pc, asm in inst_info]
    attention = [hex(int(pc)) for pc in attention_pcs]
    module.perfcct_main(
        normalized, inst_pos, hex(start_pc), hex(end_pc), attention, False
    )


def clock_analysis_bbl(
    clock_analysis_path: str | Path,
    db_path: str | Path,
    start_clock: int,
    end_clock: int,
    period: int = 333,
    inter_gap: bool = False,
    inner_gap: bool = False,
) -> None:
    """Run ClockAnalysis.py's legacy basic-block printer when needed."""
    module = _clock_analysis_module(clock_analysis_path)
    module.period = period
    inst_info, _, inst_avg = module.ReadDB(
        str(_path(db_path)), start_clock, end_clock, inter_gap, inner_gap
    )
    module.bbl_main(inst_info, inst_avg, inter_gap, inner_gap)


def load_gap_frame(
    db_path: str | Path,
    start_pc: int,
    end_pc: int,
    period: int = 333,
    start_cycle: int | None = None,
    end_cycle: int | None = None,
) -> pd.DataFrame:
    """Return load-only execution latency samples."""
    frame = lifetime_frame(
        db_path,
        start_pc=start_pc,
        end_pc=end_pc,
        start_cycle=start_cycle,
        end_cycle=end_cycle,
        period=period,
    ).copy()
    if frame.empty:
        raise ValueError("No instructions found in the requested PC range")

    frame["opcode"] = frame["DisAsm"].astype(str).str.lower().str.split().str[0]
    frame["is_load"] = frame["opcode"].str.startswith("ld") | frame["opcode"].str.startswith("c_ld")
    frame["load_execution_latency"] = (frame["AtBypassVal"] - frame["AtFU"]) / period
    frame = frame[frame["is_load"]].copy()
    frame = frame[
        (frame["AtFU"] > 0)
        & (frame["AtBypassVal"] >= frame["AtFU"])
    ]
    return frame[["ID", "PC", "DisAsm", "load_execution_latency"]]


def plot_load_gap_comparison(
    databases: dict[str, str | Path],
    start_pc: int,
    end_pc: int,
    period: int = 333,
    pc_count: int = 8,
) -> tuple[plt.Figure, pd.DataFrame]:
    """Compare load execution latency across configurations."""
    _, first_db = next(iter(databases.items()))
    first_samples = load_gap_frame(first_db, start_pc, end_pc, period)
    hot = (
        first_samples.groupby(["PC", "DisAsm"], as_index=False)
        .size()
        .sort_values(["size", "PC"], ascending=[False, True])
        .head(pc_count)
    )
    selected = [int(pc) for pc in hot["PC"]]
    rows = []
    for configuration, db_path in databases.items():
        samples = load_gap_frame(db_path, start_pc, end_pc, period)
        summary = (
            samples[samples["PC"].isin(selected)]
            .groupby(["PC", "DisAsm"], as_index=False)
            .agg(
                load_execution_latency=("load_execution_latency", "mean"),
                samples=("ID", "count"),
            )
        )
        summary["configuration"] = configuration
        rows.append(summary)
    result = pd.concat(rows, ignore_index=True)
    if result.empty:
        raise ValueError("No matching load instructions found for gap comparison")

    labels = [
        f"0x{int(row.PC):x}\n{row.DisAsm}" for row in hot.itertuples()
    ]
    x = np.arange(len(selected))
    width = 0.8 / max(1, len(databases))
    fig, axis = plt.subplots(figsize=(12.5, 4.8), constrained_layout=True)
    palette = ["#5f6368", "#1a73e8", "#e8710a", "#188038"]
    for index, (configuration, _) in enumerate(databases.items()):
        subset = result[result["configuration"] == configuration].set_index("PC")
        values = [
            subset.at[int(pc), "load_execution_latency"]
            if int(pc) in subset.index
            else np.nan
            for pc in selected
        ]
        offset = (index - (len(databases) - 1) / 2) * width
        bars = axis.bar(
            x + offset,
            values,
            width=width,
            label=configuration,
            color=palette[index],
        )
        value_labels = [
            f"{value:.1f}" if np.isfinite(value) and value >= 0.05 else ""
            for value in values
        ]
        axis.bar_label(bars, labels=value_labels, padding=2, fontsize=8)
    axis.set_title("Load execution latency")
    axis.set_ylabel("Cycles")
    axis.set_xticks(x, labels=labels)
    axis.grid(axis="y", alpha=0.2)
    axis.spines[["top", "right"]].set_visible(False)
    handles, legend_labels = axis.get_legend_handles_labels()
    fig.legend(
        handles,
        legend_labels,
        loc="outside upper center",
        ncols=len(databases),
        frameon=False,
    )
    return fig, result


def prefetch_stats(stats_path: str | Path) -> pd.Series:
    metric_names = {
        "pfIssued": "issued",
        "pfUseful": "useful",
        "accuracy": "accuracy",
        "coverage": "coverage",
    }
    pattern = re.compile(
        r"^system\.(?:l2_wrappers|l2_caches)(?:\d+)?\.prefetcher\."
        r"(pfIssued|pfUseful|accuracy|coverage)\s+(\S+)"
    )
    stats = {}
    for line in _path(stats_path).read_text(errors="replace").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        try:
            stats[metric_names[match.group(1)]] = float(match.group(2))
        except ValueError:
            pass
    return pd.Series(stats, dtype=float)


def plot_prefetch_stats(configurations: dict[str, str | Path]) -> tuple[plt.Figure, pd.DataFrame]:
    frame = pd.DataFrame({name: prefetch_stats(path) for name, path in configurations.items()}).T
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.2), constrained_layout=True)
    frame[[column for column in ["issued", "useful"] if column in frame]].plot.bar(ax=axes[0])
    frame[[column for column in ["accuracy", "coverage"] if column in frame]].plot.bar(ax=axes[1])
    axes[0].set_title("L2 prefetch requests")
    axes[0].set_ylabel("Count")
    axes[1].set_title("L2 prefetch quality")
    axes[1].set_ylabel("Ratio")
    axes[1].set_ylim(0, 1)
    for container in axes[0].containers:
        axes[0].bar_label(container, fmt="%.0f", padding=2)
    for container in axes[1].containers:
        axes[1].bar_label(container, fmt="%.3f", padding=2)
    for axis in axes:
        axis.tick_params(axis="x", rotation=12)
        axis.grid(axis="y", alpha=0.2)
        axis.spines[["top", "right"]].set_visible(False)
        axis.legend(frameon=False)
    return fig, frame
