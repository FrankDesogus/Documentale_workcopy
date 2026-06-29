#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES_DIR="${REPO_ROOT}/templates"
PROJECTS_DIR="${REPO_ROOT}/projects"

usage() {
	cat <<EOF
Usage: $(basename "$0") [--dry-run] <project-name>
       $(basename "$0") --help

Create a new project under projects/<project-name>/ by copying station templates.

Arguments:
  project-name   Name of the new project.
                 Allowed: letters, digits, hyphens (-), underscores (_).
                 Must not be empty, start with a hyphen, or contain spaces,
                 slashes, dots, or other special characters.

Options:
  --dry-run      Show what would be created without creating any files.
  --help, -h     Show this help and exit.

Files created in projects/<name>/:
  AGENTS.md
  CLAUDE.md
  .cursor/rules/project-rules.mdc
  docs/ai/PROJECT_BRIEF.md
  docs/ai/ARCHITECTURE.md
  docs/ai/TASKS.md
  docs/ai/DECISIONS.md
  docs/ai/REVIEW_LOG.md
  docs/ai/RUN_LOG.md
  scripts/test.sh   (executable placeholder — exits 1 until configured)

No git operations are performed. Review with 'git status' before committing.
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

validate_project_name() {
	local name="$1"
	[[ -n "${name}" ]] ||
		error "Project name cannot be empty."
	[[ "${name}" != */* ]] ||
		error "Project name cannot contain slashes."
	[[ "${name}" != *..* ]] ||
		error "Project name cannot contain '..'."
	[[ "${name}" != -* ]] ||
		error "Project name cannot start with a hyphen."
	[[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]] ||
		error "Project name '${name}' contains invalid characters. Use only letters, digits, hyphens and underscores."
}

ensure_required_templates() {
	local missing=0
	local required=(
		"${TEMPLATES_DIR}/AGENTS.md"
		"${TEMPLATES_DIR}/CLAUDE.md"
		"${TEMPLATES_DIR}/cursor-rules/project-rules.mdc"
		"${TEMPLATES_DIR}/scripts/test.sh"
		"${TEMPLATES_DIR}/docs-ai/PROJECT_BRIEF.md"
		"${TEMPLATES_DIR}/docs-ai/ARCHITECTURE.md"
		"${TEMPLATES_DIR}/docs-ai/TASKS.md"
		"${TEMPLATES_DIR}/docs-ai/DECISIONS.md"
		"${TEMPLATES_DIR}/docs-ai/REVIEW_LOG.md"
		"${TEMPLATES_DIR}/docs-ai/RUN_LOG.md"
	)
	for f in "${required[@]}"; do
		if [[ ! -f "${f}" ]]; then
			printf "MISSING template: %s\n" "${f}" >&2
			missing=1
		fi
	done
	[[ "${missing}" -eq 0 ]] ||
		error "One or more required templates are missing. Aborting."
}

print_plan() {
	local dest="$1"
	printf "Would create in %s/:\n" "${dest#"${REPO_ROOT}/"}"
	printf "  AGENTS.md\n"
	printf "  CLAUDE.md\n"
	printf "  .cursor/rules/project-rules.mdc\n"
	printf "  docs/ai/PROJECT_BRIEF.md\n"
	printf "  docs/ai/ARCHITECTURE.md\n"
	printf "  docs/ai/TASKS.md\n"
	printf "  docs/ai/DECISIONS.md\n"
	printf "  docs/ai/REVIEW_LOG.md\n"
	printf "  docs/ai/RUN_LOG.md\n"
	printf "  scripts/test.sh  (executable)\n"
}

install_file() {
	local src="$1"
	local dst="$2"
	mkdir -p "$(dirname "${dst}")"
	cp "${src}" "${dst}"
	printf "  created: %s\n" "${dst#"${REPO_ROOT}/"}"
}

create_project() {
	local name="$1"
	local dest="${PROJECTS_DIR}/${name}"

	[[ ! -e "${dest}" ]] ||
		error "Directory already exists: ${dest#"${REPO_ROOT}/"}. Will not overwrite."

	printf "== Creating project: %s ==\n\n" "${name}"

	install_file "${TEMPLATES_DIR}/AGENTS.md" "${dest}/AGENTS.md"
	install_file "${TEMPLATES_DIR}/CLAUDE.md" "${dest}/CLAUDE.md"
	install_file "${TEMPLATES_DIR}/cursor-rules/project-rules.mdc" "${dest}/.cursor/rules/project-rules.mdc"
	install_file "${TEMPLATES_DIR}/docs-ai/PROJECT_BRIEF.md" "${dest}/docs/ai/PROJECT_BRIEF.md"
	install_file "${TEMPLATES_DIR}/docs-ai/ARCHITECTURE.md" "${dest}/docs/ai/ARCHITECTURE.md"
	install_file "${TEMPLATES_DIR}/docs-ai/TASKS.md" "${dest}/docs/ai/TASKS.md"
	install_file "${TEMPLATES_DIR}/docs-ai/DECISIONS.md" "${dest}/docs/ai/DECISIONS.md"
	install_file "${TEMPLATES_DIR}/docs-ai/REVIEW_LOG.md" "${dest}/docs/ai/REVIEW_LOG.md"
	install_file "${TEMPLATES_DIR}/docs-ai/RUN_LOG.md" "${dest}/docs/ai/RUN_LOG.md"
	install_file "${TEMPLATES_DIR}/scripts/test.sh" "${dest}/scripts/test.sh"

	chmod +x "${dest}/scripts/test.sh"

	printf "\n== Done ==\n\n"
	printf "Project '%s' created at: %s\n" "${name}" "${dest#"${REPO_ROOT}/"}"
	printf "\nNext steps:\n"
	printf "  1. Fill in %s\n" "${dest#"${REPO_ROOT}/"}/docs/ai/PROJECT_BRIEF.md"
	printf "  2. Replace %s with your test command\n" "${dest#"${REPO_ROOT}/"}/scripts/test.sh"
	printf "  3. Review files: git status\n"
	printf "  4. Do NOT git add or commit until you have reviewed all files.\n"
}

# ── Argument parsing ──────────────────────────────────────────────────────────

DRY_RUN="false"
PROJECT_NAME=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--dry-run)
		DRY_RUN="true"
		shift
		;;
	-*)
		error "Unknown option: '$1'. Use --help for usage."
		;;
	*)
		if [[ -n "${PROJECT_NAME}" ]]; then
			error "Too many arguments. Expected exactly one project name."
		fi
		PROJECT_NAME="$1"
		shift
		;;
	esac
done

if [[ -z "${PROJECT_NAME}" ]]; then
	usage >&2
	exit 1
fi

validate_project_name "${PROJECT_NAME}"
ensure_required_templates

if [[ "${DRY_RUN}" == "true" ]]; then
	printf "== Dry run for: %s ==\n\n" "${PROJECT_NAME}"
	print_plan "${PROJECTS_DIR}/${PROJECT_NAME}"
	printf "\nNo files were created.\n"
	exit 0
fi

create_project "${PROJECT_NAME}"
