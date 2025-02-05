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

########################## mainwindow filling ##########################################
mainwindow_filling() {
if [[ "$GUI" ]];then
    echo 'SET@_vbox_bootrepairmenu.show()'
    echo "SET@_label_bootrepairsubtitle.set_markup('''<b>$diagnose_boot ($to_get_help_by_email_or_forum)</b>''')"
    echo "SET@_label_recommendedrepair.set_text('''$Url_report''')"
    echo "SET@_label_justbootinfo.set_text('''$Text_report''')"
    echo 'SET@_hbox_biadv.show()'
    echo 'SET@_notebook1.hide()'
    echo "SET@_label_appname.set_markup('''<b><big>Boot-Info</big></b>''')"
    echo "SET@_label_appdescription.set_text('''$diagnose_boot''')"
    echo 'SET@_logobi.show()'
    echo 'SET@_logo_bimenu.show()'
    echo "SET@_linkbutton_websitebi.show()"
fi
common_labels_fillin
set_easy_repair
}

set_easy_repair_diff() {
MAIN_MENU=Boot-Info
set_easy_repair_diff_br_and_bi
}	


_button_recommendedrepair() {
UPLOAD=pastebin
justbootinfo_br_and_bi
}

_button_justbootinfo() {
UPLOAD=""
justbootinfo_br_and_bi
}
