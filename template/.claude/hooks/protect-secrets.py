#!/usr/bin/env python3
"""Claude Code PreToolUse フック: シークレットファイルへのアクセスをブロックする

対象: .dev.vars / .dev.vars.<env> / .env / .env.<env> など
例外: *.example (サンプルファイル)

AI はシークレットファイルを読む・作る・編集することはできません。
設定が必要な場合は、人が行う手順だけを案内します。
"""
import json
import re
import sys

SECRET_NAME = re.compile(r"^\.(dev\.vars|env)(\.[\w.-]+)?$")
# Bash コマンド中のシークレットファイル名 (process.env などは対象外)
SECRET_IN_COMMAND = re.compile(r"(?:^|[\s/'\"=<>:(])(\.(?:dev\.vars|env)(?:\.[\w.-]+)?)(?=$|[\s'\";|&)<>*?\[])")


def is_secret(name: str) -> bool:
    base = name.rstrip("/").rsplit("/", 1)[-1]
    return bool(SECRET_NAME.match(base)) and not base.endswith(".example")


def check(tool: str, tool_input: dict) -> str | None:
    if tool == "Bash":
        command = tool_input.get("command", "")
        for match in SECRET_IN_COMMAND.finditer(command):
            if not match.group(1).endswith(".example"):
                return match.group(1)
        return None
    for key in ("file_path", "notebook_path", "path", "pattern", "glob"):
        value = tool_input.get(key)
        if isinstance(value, str) and (is_secret(value) or re.search(r"(^|/)\.(dev\.vars|env)\*?$", value)):
            return value
    return None


def main() -> None:
    payload = json.load(sys.stdin)
    hit = check(payload.get("tool_name", ""), payload.get("tool_input", {}) or {})
    if hit:
        print(
            f"Blocked: シークレットファイル ({hit}) へのアクセスは禁止されています。"
            "読む・作成・編集・コピーはせず、ユーザーが自分で行う手順を案内してください。",
            file=sys.stderr,
        )
        sys.exit(2)


if __name__ == "__main__":
    main()
