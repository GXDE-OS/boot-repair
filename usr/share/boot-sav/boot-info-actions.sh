#! /bin/bash
# Copyright 2011-2023 Yann MRN
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

FORCE_TEXT=yes

########################## REPAIR SEQUENCE DEPENDING ON USER CHOICE ##########################################
actions() {
display_action_settings_start
display_action_settings_end
first_actions
actions_final
}

########################## UNMOUNT ALL AND SUCCESS REPAIR ##########################################
unmount_all_and_success() {
unmount_all_and_success_br_and_bi
}

stats_diff() {
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (6). $This_may_require_several_minutes''')"
[[ "$BLKID" =~ zfs ]] && $WGETST $URLST.zfs.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (5). $This_may_require_several_minutes''')"
$WGETST $URLST.biusage.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (4). $This_may_require_several_minutes''')"
[[ "$NEWUSER" ]] && $WGETST $URLST.biuser.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (3). $This_may_require_several_minutes''')"
[[ "$DISABLEWEBCHECK" ]] && $WGETST $URLST.nointernetchk.$CODO
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (2). $This_may_require_several_minutes''')"
[[ ! "$UPLOAD" ]] && $WGETST $URLST.local.$CODO	
[[ "$GUI" ]] && echo "SET@_label0.set_text('''$LAB (1). $This_may_require_several_minutes''')"	
[[ "$UPLOAD" ]] && $WGETST $URLST.online.$CODO
}

