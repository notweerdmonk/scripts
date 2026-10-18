# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org/>

# tabulate.awk - Format a colon- or pipe-delimited text stream as a table.
# notweerdmonk 2026

# Split text into words and group them into lines no longer than width.
# Store each resulting line in lines[] and its length in lengths[].
# Returns the number of lines produced.
function wrap(text, width, lines, lengths,    n, words, i, word, line, count) {
    delete lines
    delete lengths

    # Split on one or more whitespace characters.
    n = split(text, words, /[[:space:]]+/)
    line = ""
    count = 0

    for (i = 1; i <= n; i++) {
        word = words[i]
        if (word == "")
            continue

        # Start a line, or add the word if it still fits.
        if (line == "")
            line = word
        else if (length(line) + 1 + length(word) <= width)
            line = line " " word
        else {
            # Save the current line and begin the next one.
            lines[++count] = line
            lengths[count] = length(line)
            line = word
        }
    }

    # Save the final line, if there is one.
    if (line != "") {
        lines[++count] = line
        lengths[count] = length(line)
    }

    return count
}

BEGIN {
    # Input fields are colon-delimited by default.
    FS = ":"

    # Read optional command-line arguments:
    #   -x / --comments  Enable comment-style input parsing.
    #   Remaining arguments set the three column headers.
    arg_idx = 1
    comments = (ARGC > arg_idx && match(ARGV[arg_idx], /^(-x|--comments)/) ? arg_idx++ : 0)
    h1 = (ARGC > arg_idx ? ARGV[arg_idx++] : "file")
    h2 = (ARGC > arg_idx ? ARGV[arg_idx++] : "line")
    h3 = (ARGC > arg_idx ? ARGV[arg_idx++] : "text")

    # Remove the options and headers from ARGV so awk does not treat them
    # as input filenames.
    delete ARGV[--arg_idx]
    delete ARGV[--arg_idx]
    delete ARGV[--arg_idx]
    if (arg_idx > 1) {
        delete ARGV[--arg_idx]
    }

    # Start each column width at least as wide as its header.
    w1 = length(h1)
    w2 = length(h2)
    w3 = length(h3)
}

{
    # Remove optional leading and trailing pipe characters from the record.
    sub(/^\|[[:space:]]*/, "", $0)
    sub(/[[:space:]]*\|$/, "", $0)
    line = $0

    if (comments) {
        # Remove a leading file:line: /* TODO: prefix from the text.
        sub(/^([^:]+):([0-9]+):[[:space:]]*\/\*[[:space:]]*TODO:[[:space:]]*/, "", line)

        # Remove trailing comment-closing characters and whitespace.
        sub(/[[:space:]]+\*?\/?[[:space:]]*$/, "", line)

        # Extract the file and line columns from the original record.
        match($0, /^([^:]+):([0-9]+):/, m)
    } else {
        # Remove repeated "column | " prefixes from the text portion.
        gsub(/[^|]+\| /, "", line)

        # Extract the first two pipe-delimited columns.
        match($0, /^[[:space:]]*([^|]+)\|([^|]+)\|/, m)
    }

    # Trim whitespace from the extracted first column.
    sub(/^[[:space:]]*/, "", m[1])
    sub(/[[:space:]]*$/, "", m[1])
    col1 = m[1]

    # Trim whitespace from the extracted second column.
    sub(/^[[:space:]]*/, "", m[2])
    sub(/[[:space:]]*$/, "", m[2])
    col2 = m[2]

    # Trim whitespace from the remaining text.
    sub(/^[[:space:]]*/, "", line)
    sub(/[[:space:]]*$/, "", line)

    # Keep each parsed row until the END block prints the table.
    rows[++n] = col1 SUBSEP col2 SUBSEP line

    # Expand column widths to fit the data, with a maximum width of 60.
    if (length(col1) > w1) w1 = length(col1)
    if (w1 > 60) w1 = 60
    if (length(col2)  > w2) w2 = length(col2)
    if (w2 > 60) w2 = 60
    if (length(line) > w3) w3 = length(line)
    if (w3 > 60) w3 = 60
}

# Earlier END-block implementation, which split cells at fixed character
# positions rather than wrapping at word boundaries.
#END {
#    printf "| %-*s | %-*s | %-*s |\n", w1, h1, w2, h2, w3, h3
#
#    printf "|"
#    for (i = 0; i < w1 + 2; i++) printf "-"
#    printf "|"
#    for (i = 0; i < w2 + 2; i++) printf "-"
#    printf "|"
#    for (i = 0; i < w3 + 2; i++) printf "-"
#    printf "|\n"
#
#    for (i = 1; i <= n; i++) {
#        split(rows[i], a, SUBSEP)
#
#        c1start = 1
#        c2start = 1
#        c3start = 1
#
#        c1len = length(a[1])
#        c2len = length(a[2])
#        c3len = length(a[3])
#
#        while (c1len > 0 || c2len > 0 || c3len > 0) {
#            col1 = substr(a[1], c1start, w1)
#            col2 = substr(a[2], c2start, w2)
#            col3 = substr(a[3], c3start, w3)
#
#            c1start += length(col1)
#            c2start += length(col2)
#            c3start += length(col3)
#
#            c1len -= w1
#            c2len -= w2
#            c3len -= w3
#
#            printf "| %-*s | %-*s | %-*s |\n", w1, col1, w2, col2, w3, col3
#
#        }
#    }
#}

END {
    # Wrap each header to its column width.
    nh1 = wrap(h1, w1, head1, headlen1)
    nh2 = wrap(h2, w2, head2, headlen2)
    nh3 = wrap(h3, w3, head3, headlen3)

    # Set header height to the tallest wrapped header.
    hheight = nh1
    if (nh2 > hheight) hheight = nh2
    if (nh3 > hheight) hheight = nh3
    if (hheight < 1) hheight = 1

    # Print header lines, padding shorter headers with blank cells.
    for (j = 1; j <= hheight; j++) {
        printf "| %-*s | %-*s | %-*s |\n",
            w1, (j <= nh1 ? head1[j] : ""),
            w2, (j <= nh2 ? head2[j] : ""),
            w3, (j <= nh3 ? head3[j] : "")
    }

    # Print the separator beneath the headers.
    printf "| "
    for (j = 0; j < w1; j++) printf "-"
    printf " | "
    for (j = 0; j < w2; j++) printf "-"
    printf " | "
    for (j = 0; j < w3; j++) printf "-"
    printf " |\n"

    # Wrap and print each stored data row.
    for (i = 1; i <= n; i++) {
        split(rows[i], a, SUBSEP)

        nr1 = wrap(a[1], w1, cell1, celllen1)
        nr2 = wrap(a[2], w2, cell2, celllen2)
        nr3 = wrap(a[3], w3, cell3, celllen3)

        # Set row height to the tallest wrapped cell.
        height = nr1
        if (nr2 > height) height = nr2
        if (nr3 > height) height = nr3
        if (height < 1) height = 1

        # Print the row line by line, padding shorter cells with blanks.
        for (j = 1; j <= height; j++) {
            printf "| %-*s | %-*s | %-*s |\n",
                w1, (j <= nr1 ? cell1[j] : ""),
                w2, (j <= nr2 ? cell2[j] : ""),
                w3, (j <= nr3 ? cell3[j] : "")
        }
    }
}
