#!/usr/bin/env zsh
#
# This script is intended to be used in the base directory.
# e.g. ./tidyScripts/shebang.sh
#
# It replaces #!/usr/bin/ruby with #!/usr/bin/env ruby
#

setopt rcquotes
# allows escape of"'" as ''; e.g. 'don''t' --> don't

find . -type f -name "*rb" -exec sed -i 's:/usr/bin/ruby:/usr/bin/env ruby:' {} \;
