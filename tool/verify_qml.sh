#!/usr/bin/env bash
# Verifies the Meridian QML library: generated files are current, every QML
# file lints clean, and the Qt Quick Test suite passes offscreen.
#
#   tool/verify_qml.sh            uses qmllint/qmltestrunner from PATH or qmake6
#   QT_HOST_BINS=/path tool/verify_qml.sh
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

find_tool() {
    local name="$1" dir
    if [[ -n "${QT_HOST_BINS:-}" && -x "$QT_HOST_BINS/$name" ]]; then
        echo "$QT_HOST_BINS/$name"; return
    fi
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"; return
    fi
    for qmake in qmake6 qmake; do
        if command -v "$qmake" >/dev/null 2>&1; then
            dir="$("$qmake" -query QT_HOST_BINS)"
            if [[ -x "$dir/$name" ]]; then echo "$dir/$name"; return; fi
        fi
    done
    echo "missing Qt tool: $name" >&2
    exit 1
}

qmllint="$(find_tool qmllint)"
qmltestrunner="$(find_tool qmltestrunner)"
echo "Qt: $("$(find_tool qmake6 2>/dev/null || find_tool qmake)" -query QT_VERSION 2>/dev/null || echo unknown)"

python3 tool/generate_qml.py --check

mapfile -t files < <(find qml -name '*.qml' | sort)
# Lint from outside the module directory so its qmldir resolves as an import.
(cd / && "$qmllint" --max-warnings 0 -I "$root/qml" "${files[@]/#/$root/}")

QT_QPA_PLATFORM=offscreen QTEST_DISABLE_STACK_DUMP=1 \
    "$qmltestrunner" -import qml -input qml/tests
