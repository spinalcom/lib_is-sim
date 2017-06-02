# Copyright 2015 SpinalCom  www.spinalcom.com
# Copyright 2014 jeremie Bellec
#
# This file is part of SpinalCore.
#
# SpinalCore is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpinalCore is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with SpinalCore. If not, see <http://www.gnu.org/licenses/>.



#
class LoginBar extends View
    constructor: ( @el, @config ) ->
        super @config
        @edit_view = new UserEditView

        @he = new_dom_element
            parentNode: @el
            nodeName   : "div"
            style:
                display : "flex"
                position: "absolute"
                left    : 0
                right   : 0
                top     : "0px"
                height  : "30px"
                withd   : "100%"
                borderBottom : "1px solid grey" #"#4dbce9"

    onchange: () ->
        if @config.has_been_modified
            while @he.firstChild?
                @he.removeChild @he.firstChild

            # logo_div = new_dom_element
            #     parentNode: @he
            #     nodeName   : "div"
            #     className  : "logo"
            logo_img = new_dom_element
              parentNode: @he
              nodeName: "img"
              src: "utility_admin-dashboard/assets/img/smart-building-platform.png"
              style:
                height  : "100%"
                withd   : "100%"

            logo_txt = new_dom_element
              parentNode: @he
              nodeName: "p"
              txt       : "Studio"
              style:
                marginTop: "10px"
                marginLeft: "33%"
                fontSize: "14px"


            logo_txt = new_dom_element
              parentNode: @he
              nodeName: "user_name"
              txt       : config.user
              style:
                position: "absolute"
                right: 0
                fontSize: "14px"
                marginRight: "8%"
                marginTop: "10px"



            logo_profil = new_dom_element
              parentNode: @he
              nodeName: "img"
              src: "utility_admin-dashboard/assets/img/home_user.jpg"
              style:
                height  : "80%"
                withd   : "80%"
                position: "absolute"
                right: 0
                marginRight: "40px"
                borderRadius: "40px"
                marginTop: "3px"

             logout_div = new_dom_element
                parentNode: @he
                nodeName   : "div"
                className  : "logout_div"
                onclick: ( evt ) =>
                    # if (config.user)
                    #   delete config.user;
                    # if (config.password)
                    #   delete config.password;
                    localStorage.removeItem('spinal_user_connect');
                    # if (error)
                    #   window.location = "login-dashboard.html#error";
                    # else {
                    #   window.location = "login-dashboard.html";
                    # }
                    window.location = "login-dashboard.html"
                style:
                    position: "absolute"
                    right: 0
                #     color: "red"


#################  Decomment to add organisation and user infos  ##################
#
#             user_div = new_dom_element
#                 parentNode: @he
#                 nodeName   : "div"
#                 className  : "user_icon_div"
#                 txt        : @config.account.email
#                 style:
#                     height  : "25px"
#                     padding : "5px 0 0 27px"
#                     lineHeight : "23px"
#                     fontSize   : "14px"
#                     textAlign  : "left"
#                     cursor : "pointer"
#                 onmousedown: ( evt ) =>
#                     @edit_view.edit_user evt
#
#
#             organisation_div = new_dom_element
#                 parentNode: @he
#                 nodeName   : "div"
#                 className  : "organisation_icon_div"
#                 txt        : if (@config.selected_organisation[0] instanceof Organisation) then @config.selected_organisation[0].name else "Select your organisation"
#                 style:
#                     height  : "25px"
#                     padding : "5px 0 0 25px"
#                     lineHeight : "23px"
#                     fontSize   : "14px"
#                     textAlign  : "left"
#                     cursor : "pointer"
#                 onmousedown: ( evt ) =>
#                     myWindow = window.open '',''
#                     myWindow.document.location = "organisation.html"
#                     myWindow.focus()
#######################################################################################
