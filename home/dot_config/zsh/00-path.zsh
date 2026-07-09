# PATH additions. Homebrew shellenv is set in ~/.zprofile.

# Global Composer tools
export COMPOSER_HOME="$HOME/.composer"
path=("$COMPOSER_HOME/vendor/bin" $path)

# MySQL client (keg-only formula)
if command -v brew >/dev/null 2>&1; then
  path=("$(brew --prefix)/opt/mysql-client/bin" $path)
fi

typeset -U path   # de-duplicate
export PATH
