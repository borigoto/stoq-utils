#
# Copyright (C) 2014 Async Open Source <http://www.async.com.br>
# All rights reserved
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., or visit: http://www.gnu.org/.
#
# Author(s): Stoq Team <stoq-devel@async.com.br>
#

set -e

# FIXME: This will not work when calling this script from stoq-utils
TOOLSDIR=`dirname $0`
cd $TOOLSDIR/../..
CHECKOUT=`pwd`
cd - > /dev/null

if [ -d "$CHECKOUT/.repo/" ]; then
    # When using repo, put 'stoq' on TREE for PS1
    TREE="stoq"
else
    # If no repo, use the base directory name as the branch for PS1
    TREE=`basename $CHECKOUT`
fi

for PROJECT in `ls $CHECKOUT | sort`; do
    PROJECT_PATH="$CHECKOUT/$PROJECT"
    # Make sure we add new hooks every time the shell inits
    if [ -d "$PROJECT_PATH/utils/git-hooks/" ]; then
        cp -au $PROJECT_PATH/utils/git-hooks/* \
               $PROJECT_PATH/.git/hooks/
    fi

    PO_FILE="$PROJECT_PATH/po/pt_BR.po"
    MO_DIR="$PROJECT_PATH/locale/pt_BR/LC_MESSAGES"
    MO_FILE="$MO_DIR/stoq.mo"
    # Compile translations for pt_BR if they exist and are newer than existing
    if [ -f "$PO_FILE" ] && [ "$PO_FILE" -nt "$MO_FILE" ]; then
        mkdir -p $MO_DIR
        msgfmt $PO_FILE -o $MO_FILE
    fi

    # Put all projects inside checkout on PYTHONPATH and the ones having a
    # bin directory on PATH
    EXTRA_PYTHONPATH="$PROJECT_PATH:$EXTRA_PYTHONPATH"
    if [ -d "$PROJECT_PATH/bin/" ]; then
        EXTRA_PATH="$PROJECT_PATH/bin:$EXTRA_PATH"
    fi
done

SCRIPT=`tempfile --suffix=.sh`
trap "rm $SCRIPT" EXIT

cat <<EOF > $SCRIPT
# This list of environment variables are placed before the source lines,
# so that they can be customized in the users ~/.bashrc
export STOQ_BRANCH=$TREE
export STOQLIB_TEST_QUICK=1
export STOQ_DISABLE_CRASHREPORT=1

test -f /etc/bash_completion && source /etc/bash_completion
test -f ~/.bashrc && source ~/.bashrc

# This is updated after the users environment variables has been loaded
# No need to put ':' separating them because there should already be a
# trailing ':' because of the logic above for creating them
export PATH=$EXTRA_PATH\$PATH
export PYTHONPATH=$EXTRA_PYTHONPATH\$PYTHONPATH

# cd to the working tree, so we are ready to work!
cd $CHECKOUT
EOF

# We should be able to setup everything without having to call bash again.
# This will make this usable for people using other shells (like fish)
bash --rcfile $SCRIPT
