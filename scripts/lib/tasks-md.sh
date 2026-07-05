# shellcheck shell=bash
# Funzioni condivise, sola lettura, per estrarre informazioni da docs/ai/TASKS.md.
# Pensate per essere sourced da altri script (station-status.sh, station-next-task.sh).

# tasks_md_first_row FILE SECTION
# Stampa "ID|Titolo" della prima riga dati valida della sezione data
# ("In corso" | "Backlog" | "Completati"). Vuoto se non trovata.
tasks_md_first_row() {
	local file="$1"
	local section="$2"
	awk -v section="${section}" '
		/^## / {
			insec = ($0 ~ ("^## " section "([[:space:]]|$)")) ? 1 : 0
			next
		}
		insec && /^\|/ {
			line = $0
			test = line
			gsub(/[ \t]/, "", test)
			gsub(/[|:-]/, "", test)
			if (test == "") next
			split(line, cols, "|")
			id = cols[2]
			title = cols[3]
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)
			if (id == "" || id == "ID") next
			print id "|" title
			exit
		}
	' "${file}"
}

# tasks_md_count_rows FILE SECTION
# Conta le righe dati valide (ID non vuoto, non header) nella sezione data.
tasks_md_count_rows() {
	local file="$1"
	local section="$2"
	awk -v section="${section}" '
		/^## / {
			insec = ($0 ~ ("^## " section "([[:space:]]|$)")) ? 1 : 0
			next
		}
		insec && /^\|/ {
			line = $0
			test = line
			gsub(/[ \t]/, "", test)
			gsub(/[|:-]/, "", test)
			if (test == "") next
			split(line, cols, "|")
			id = cols[2]
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
			if (id == "" || id == "ID") next
			count++
		}
		END { print count + 0 }
	' "${file}"
}

# tasks_md_task_snippet FILE TASK_ID
# Stampa la prima riga di contenuto non vuota trovata nel blocco di dettaglio
# del task (heading "### TASK-ID ..."). Best-effort, vuoto se non trovata.
tasks_md_task_snippet() {
	local file="$1"
	local task_id="$2"
	awk -v id="${task_id}" '
		found && /^##[^#]/ { exit }
		found && /^###[^#]/ { exit }
		$0 ~ ("^###[[:space:]]+" id) { found=1; next }
		found {
			line = $0
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			gsub(/\*\*/, "", line)
			if (line != "" && line !~ /^#/ && desc == "") desc = line
		}
		END { print desc }
	' "${file}"
}
