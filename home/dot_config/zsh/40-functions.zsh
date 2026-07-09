# Shell functions.

# Create a directory (and parents) then cd into it.
take() {
  mkdir -p "$1" && cd "$1"
}
