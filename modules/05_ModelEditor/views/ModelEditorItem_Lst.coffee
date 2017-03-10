# Copyright 2015 SpinalCom  www.spinalcom.com

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
class ModelEditorItem_Lst extends ModelEditorItem
    constructor: ( params ) ->
        super params

        @lst = []
        @dst = []

    onchange: ->
        if @model.has_been_directly_modified() or @lst.length == 0
            for v in @lst
                if v.destructor
                  v.destructor()
                else
                  if v.parentNode?
                      v.parentNode.removeChild v

            for v in @dst
                v.parentNode.removeChild v

            @dim = ModelEditorItem_Lst._rec_dim @model
            if @model.length < 50
                # w = if @dim == 1 then @ew / @model.length else @ew
                w = @ew
                if @model.length
                    br = new_dom_element
                      parent: this
                      nodeName: 'br'
                    @ed.appendChild br
                    @lst = for i in @model
                        new_model_editor
                            el        : @ed
                            model     : i
                            parent    : this
                            item_width: w
                        br = new_dom_element
                          parent: this
                          nodeName: 'div'
                          style:
                            height:'5px'
                        @ed.appendChild br
                    @dst = []
                else
                    @lst = []
                    @dst = [
                        new_dom_element
                            parentNode: @ed
                            style     :
                                width: @ew + "%"
                                background: "#123456"
                    ]


                if @lst.length and @ev?
                    @ev.onmousedown = =>
                        @get_focus()?.set @lst[ 0 ].process_id


        @fd = true

    ok_for_label: ->
        ModelEditorItem_Lst._rec_dim( @model ) == 1

    @_rec_dim: ( model ) ->
        while model.disp_only_in_model_editor?()
            model = model.disp_only_in_model_editor()
        d = model.dim true

        if d and model[ 0 ]?
            return d + ModelEditorItem_Lst._rec_dim model[ 0 ]
        return d
