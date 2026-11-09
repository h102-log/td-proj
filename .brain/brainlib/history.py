"""git 히스토리: 전체 커밋 목록(색인 때)과 함수 한 개의 줄 히스토리(git log -L, 질의 때)."""
from __future__ import annotations

from .util import extract_ids, extract_prs, git

FMT = "%x1e%H%x1f%h%x1f%ad%x1f%an%x1f%P%x1f%s%x1f%b%x1d"


def commits() -> list[dict]:
    out = git("log", "HEAD", "--date=short", f"--format={FMT}", "--name-only", timeout=120)
    rows = []
    for rec in out.split("\x1e")[1:]:
        head, _, files = rec.partition("\x1d")
        parts = head.split("\x1f")
        if len(parts) < 7:
            continue
        full, short, date, author, parents, subject, body = parts[:7]
        body = body.strip()
        text = subject + "\n" + body
        rows.append({
            "hash": full, "short": short, "date": date, "author": author, "subject": subject.strip(), "body": body,
            "merge": len(parents.split()) > 1,
            "files": [f.strip() for f in files.strip().split("\n") if f.strip()],
            "ids": extract_ids(text) + extract_prs(text),
        })
    return rows


def is_shallow() -> bool:
    return git("rev-parse", "--is-shallow-repository").strip() == "true"


def head() -> str:
    return git("rev-parse", "HEAD").strip()


def dirty_files() -> set[str]:
    out = git("status", "--porcelain", "--untracked-files=no")
    return {line[3:].strip() for line in out.split("\n") if line.strip()}


def show_head(path: str) -> str | None:
    out = git("show", f"HEAD:{path}")
    return out if out else None


def line_history(path: str, start: int, end: int, limit: int = 40) -> list[tuple]:
    """HEAD 기준 path:start-end 를 바꾼 커밋들(새것부터): [(짧은 해시, 날짜, 제목)]."""
    out = git("log", f"-L{start},{end}:{path}", "--no-patch", "--date=short", "--format=%h%x1f%ad%x1f%s", f"-n{limit}", "HEAD", timeout=60)
    rows = []
    for line in out.split("\n"):
        p = line.split("\x1f")
        if len(p) == 3:
            rows.append((p[0], p[1], p[2]))
    return rows
