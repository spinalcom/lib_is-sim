# Copyright 2015 SpinalCom  www.spinalcom.com
#
# This file is part of Soja.
#
# SpinalCore is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Soda is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with Soda. If not, see <http://www.gnu.org/licenses/>.



#
# @selected is a list of paths
#
class TreeView extends View
    constructor: ( @el, @roots, @selected = new Lst, @visible = new Model, @closed = new Lst, @visibility_context = new Str "default_visibility_context") ->            
        super [ @roots, @closed, @selected, @visible, @visibility_context ]
        if not @visible[ @visibility_context.get() ]?
            @visible.add_attr @visibility_context.get(), new Lst

        # prefix for class names
        @css_prefix = ""
        
        # used by the default make_line method
        @icon_width = 18
        
        #
        @line_height = 18
        
        # use when there is multiple instance of the same object in the tree
        @index_color_for_tree = 0
        
        # kind of tab space for indentation of tree items
        @sep_x = @line_height * 4 / 4
        
        # div to show where items are inserted (drag and drop / ...)
        @_line_div = new_dom_element
            className: @css_prefix + "TreeLine"
            style    :
                position: "absolute"
                height  : 2
                right   : 0

        # used to destroy elements from previous rendering
        @_created_elements = []
        
        # used to link model_id of tree item to dom
        @linked_id_dom = {}
        
    # may be redefined depending on how the user want to construct the graph. Return the children of item
    get_children_of: ( item ) ->
        item._children
        
    # may be redefined depending on how the user want to construct the graph. Return the children of item
    get_output_of: ( item ) ->
        item._output
        
        #         tab = new Lst
        #         for output in item._output
        #             tab.push output
        #         for ch in item._children
        #             tab.push ch
        #         return tab

    # may be redefined
    insert_child: ( par, pos, chi ) ->
        if not par._children?
            par.add_attr _children: []
        par._children.insert pos, [ chi ]

    # may be redefined depending on how the user want to construct the graph. Return the children of item
    get_viewable_of: ( item ) ->
        item._viewable

    get_computable_of: ( item ) ->
#         console.log (item instanceof TreeItem_Computable)
        return (item instanceof TreeItem_Computable)
        #item.auto_compute
        
    # may be redefined depending on how the user want to display items. Return the children of item
    get_name_of: ( item ) ->
        return item._name

    # may be redefined depending on how the user want to display items. Return the children of item
    get_name_class_of: ( item ) ->
        return item._name_class

    # may be redefined depending on how the user want to display items.
    get_ico_of: ( item ) ->
        return item._ico

    # called each time there's a change in the tree
    onchange: ->
        if @_need_render()
#             console.log "in onchangetreeview"
            @_update_repr()
            @_render()
        for el in @flat
            model = el.item
            if @linked_id_dom[ model.model_id ]?
                if @get_children_of( model )?.has_been_directly_modified()
                    dom_elem = @linked_id_dom[ model.model_id ]
                    dom_elem.classList.add "TreeJustModified"
                if @get_output_of( model )?.has_been_directly_modified()
                    dom_elem = @linked_id_dom[ model.model_id ]
                    dom_elem.classList.add "TreeJustModified"
                        
    #looking for duplication in tree
    _get_color_element: ( info ) ->
        col = "#262626"
        # BUG
#         c = 0
#         for elem, i in @flat
#             if elem.item.equals info.item
#                 c++
#             if c >= 2
#                 col = "green"
        #                 #TODO need to know if color of duplicate item is already choosen or not
        return col
    
        
    _get_next_color_element: ->
        tab = [ "lightSeaGreen" ] #, "orange", "lightGreen", "yellow", "lightPink"
        if @index_color_for_tree == tab.length - 1
            @index_color_for_tree = 0
        else
            @index_color_for_tree++
        return tab[ @index_color_for_tree ]
        
        
    _render: ->
            
        # remove old elements
        for c in @_created_elements
            @el.removeChild c
        @_created_elements = []
        @linked_id_dom = {}
        pos_y = 0
        
        # header title (bad)
        @height_header = @line_height + 10
        @height_icon_bar = 0
        pos_y += @height_header
        pos_y += @height_icon_bar
        
        @treeContainer = new_dom_element
            nodeName  : "div"
            id        : "ContainerTreeView"
            parentNode: @el
        @_created_elements.push @treeContainer
        
        
        for info in @flat
            do ( info ) =>
                div = new_dom_element
                    parentNode: @treeContainer
                    className : @css_prefix + "TreeView"
                    my_item   : info # this is really bad, but necessary for external drag and drop
                    style     :
                        position: "absolute"
                        top     : pos_y
                        height  : @line_height
                        lineHeight : @line_height + "px"
                        left    : 0
                        right   : 0
                        overflow: "hidden"
                        color   : @_get_color_element info
                    
                    #                     onmousedown: ( evt ) =>
                    #                         evt = window.event if not evt?
                    # 
                    #                         mouse_b = if evt.which?
                    #                             if evt.which > 2
                    #                                 "LEFT"
                    #                             else if evt.which == 2 
                    #                                 "MIDDLE"
                    #                             else
                    #                                 "RIGHT"
                    #                         else
                    #                             if evt.button < 2
                    #                                 "LEFT"
                    #                             else if evt.button == 4 
                    #                                 "MIDDLE"
                    #                             else
                    #                                 "RIGHT"
                    #                         
                    #                         if mouse_b == "RIGHT"
                    #                             evt.stopPropagation()
                    #                             evt.cancelBubble = true
                    #                             # ... rien ne marche sous chrome sauf document.oncontextmenu = => return false 
                    #                             document.oncontextmenu = => return false
                    
                    onclick: ( evt ) =>
                        if evt.ctrlKey
                            @selected.toggle info.item_path
                        else
                            @selected.clear()
                            @selected.push info.item_path
                        return true
                            
                    draggable: true
                
                    ondragstart: ( evt ) =>
                        @drag_info = info
                        @drag_kind = if evt.ctrlKey then "copy" else "move"
                        evt.dataTransfer.effectAllowed = @drag_kind
                        evt.dataTransfer.setData('text/plain', '') #mozilla need data to allow drag
        
                    ondragend: ( evt ) =>
                        if @_line_div.parentNode == @el
                            @el.removeChild @_line_div
                        evt.returnValue = false
                        return false
                        
                    ondragover: ( evt ) =>
                        for num in [ info.path.length - 1 .. 0 ]
                            par = info.path[ num ]
                            if @_accept_child par, @drag_info
                                # by default, add after the first parent that accepts @drag_info
                                n = par.num_in_flat
                                # but if tries to insert into th the children of par if possible
                                if num + 1 < info.path.length
                                    bar = info.path[ num + 1 ]
                                    n = bar.num_in_flat + @_nb_displayed_children( bar )
                                @_line_div.style.top  = @line_height * ( n + 1 ) + @height_header + @height_icon_bar
                                @_line_div.style.left = @sep_x * ( num + 1 )
                                @el.appendChild @_line_div
                                break
                        evt.returnValue = false
                        return false
                        
                    ondragleave : ( evt ) =>
                        if @_line_div.parentNode == @el
                            @el.removeChild @_line_div
                        evt.returnValue = false
                        return false
        
                    ondrop : ( evt ) =>
#                         r = TreeView.default_types[ 0 ]
#                         r evt, info

                                    
                                    
#                         console.log evt, evt.dataTransfer.files, info
#                         # Drop of file from browser to tree
#                         file.load ( m, err ) =>
# #                             #if name end like a picture (png, jpg, tiff etc)
#                             img_item = new ImgItem "/sceen/_?u=" + m._server_id, app
#                             img_item._name.set file.name
#                             @modules = app.data.modules
#                             for m in @modules
#                                 if m instanceof TreeAppModule_ImageSet
#                                     m.actions[ 1 ].fun evt, app, img_item
                        
                        # External drag and drop
                        if typeof files == "undefined" #Drag and drop
                            evt.stopPropagation()
                            evt.returnValue = false
                            evt.preventDefault()
                            files = evt.dataTransfer.files
                        if evt.dataTransfer.files.length > 0
                            for file in files 
                                format = file.type.indexOf "image"
                                console.log "TODO, need to create an Img who contains a Path"
                                if format isnt -1
                                    pic = new ImgItem file.name
                                    accept_child = info.item.accept_child pic
                                    if accept_child == true
                                        info.item.add_child pic
                                        info.item.img_collection.push pic


                        # Internal drop when moving item
                        for num in [ info.path.length - 1 .. 0 ]
                            par = info.path[ num ]
                            if @_accept_child par, @drag_info
                                if @drag_kind == "move" and @drag_info.parents.length
                                    p = @drag_info.parents[ @drag_info.parents.length - 1 ]
                                    @get_children_of( p.item )?.remove_ref @drag_info.item

                                n = 0
                                if num + 1 < info.path.length
                                    n = info.path[ num + 1 ].num_in_parent + 1
                                
                                @insert_child par.item, n, @drag_info.item
                                break
                            
                        evt.returnValue = false
                        evt.stopPropagation()
                        evt.preventDefault()
                        return false

                
                @linked_id_dom[ info.item.model_id ] = div
                
                #surligne les réfrence à l'element selectionné
                is_ref = false
                for elem in @flat
                    if elem.item.equals info.item
                        if not @selected.contains info.item_path
                            if @selected.contains elem.item_path
                                is_ref = true
                                break
                if is_ref
                    div.className += " #{@css_prefix}TreePartiallySelected"
                
                #surligne l'element selectionné
                if @selected.contains info.item_path
                    div.className += " #{@css_prefix}TreeSelected"
                else if @closed.contains( info.item_path ) and @_has_a_selected_child( info.item, info.item_path )
                    div.className += " #{@css_prefix}TreePartiallySelected"
                
                
#                 @_created_elements.push div
                pos_y += @line_height
                
                @_add_tree_signs div, info
                @_make_line      div, info
                

    #
    _add_tree_signs: ( div, info ) ->
        pos_x = 0
        
        for p in info.parents
            if p.num_in_parent < p.len_sibling - 1
                new_dom_element
                    parentNode: div
                    nodeName  : 'span'
                    className : @css_prefix + "TreeIcon_tree_cnt"
                    style:
                        position: "absolute"
                        top     : 0
                        left    : pos_x
                        width   : @sep_x
                        height  : @line_height
            pos_x += @sep_x
        
        tc = @css_prefix + "TreeIcon_tree"
        num_i = info.num_in_parent
        len_i = info.len_sibling
        if len_i == 1
            tc += "_end"
        else if num_i == 0 and info.path.length == 1
            tc += "_beg"
        else if num_i < len_i - 1
            tc += "_mid"
        else
            tc += "_end"
        if @get_children_of( info.item )?.length or @get_output_of( info.item )?.length
            if @closed.contains info.item_path
                tc += "_add"
            else
                tc += "_sub"        
        
        # the * - | sign
        new_dom_element
            parentNode : div
            className  : tc
            nodeName   : 'span'
            onmousedown: ( evt ) =>
                @closed.toggle info.item_path
            style:
                position: "absolute"
                top     : 0
                left    : pos_x
                width   : @sep_x
                height  : @line_height

    #
    _make_line: ( div, info ) ->
        pos_x = @sep_x * info.path.length
        
        # icon
#         ico = @get_ico_of( info.item )?.get()
#         if ico?.length
#             new_dom_element
#                 parentNode : div
#                 nodeName   : 'img'
#                 src        : ico
#                 alt        : ""
#                 style      :
#                     position : "absolute"
#                     top      : 0
#                     left     : pos_x
#                     height   : @line_height
#             
#             pos_x += @line_height # * 12 / 16
            
        name = new_dom_element
            parentNode: div
            txt       : info.name
            className : info.name_class
            style     :
                position: "absolute"
                top     : 0
                height  : @line_height
                left    : pos_x
                right   : 0
#             onclick: =>
#                 name.contentEditable = true

        if info.is_an_output
            name.style.textAlign = "left"
            name.style.color = "red"
            name.style.right = "20px"
                
        # computable
        if @get_computable_of( info.item )
#             console.log info.item._computation_mode.get()
#             console.log info.item._computation_state.get()
#             if not info.item._computation_mode.get() and not info.item._computation_state.get()
#                 console.log "TreeComputableItem"
            classTitle = "TreeComputableItem"
        
#             else if info.item._computation_state.get() # or info.item._pending_state.get() or info.item._processing_state.get() or info.item._finish_state.get()
#                 classTitle = "TreeProcessingItem"

            new_dom_element
                parentNode : div
                className  : @css_prefix + classTitle
                onmousedown: ( evt ) =>
                    if not info.item._computation_mode.get() and not info.item._computation_state.get()
                        info.item.do_it()
                style      :
                    position: "absolute"
                    top     : 0
                    right   : 22
                    
        
        # visibility
        if @get_viewable_of( info.item )?.toBoolean()
            new_dom_element
                parentNode : div
                className  : if info.item in @visible[ @visibility_context.get() ] then @css_prefix + "TreeVisibleItem" else if @selected.contains info.item_path then @css_prefix + "TreeSelectedItem" else @css_prefix + "TreeHiddenItem"
                onmousedown: ( evt ) =>
                    #if not info.get "user_cannot_change_visibility"
                    if info.item._allow_vmod? == false or info.item._allow_vmod.get()
                        @visible[ @visibility_context.get() ].toggle_ref info.item
                style      :
                    position: "absolute"
                    top     : 0
                    right   : 0
                
                
    #        
    _update_repr: ->
        @flat = []
        @repr = for num_item in [ 0 ... @roots.length ]
            @_update_repr_rec @roots[ num_item ], num_item, @roots.length, []
        
    _update_repr_rec: ( item, number, length, parents, output = false ) ->
        info =
            item         : item
            name         : @get_name_of( item ).get()
            name_class   : @get_name_class_of( item )?.get() or ""
            num_in_parent: number
            len_sibling  : length
            children     : []
            outputs      : []
            parents      : parents
            path         : ( p for p in parents )
            item_path    : ( p.item for p in parents )
            num_in_flat  : @flat.length
            is_an_output : output

        info.path.push info
        info.item_path.push item
        
        @flat.push info

        if not @closed.contains( info.item_path )
            ch = @get_children_of( item )
            if ch?
                info.children = for num_ch in [ 0 ... ch.length ]
                    par = ( p for p in parents )
                    par.push info
                    @_update_repr_rec ch[ num_ch ], num_ch, ch.length, par, false
                    
            ch = @get_output_of( item )
            if ch?
                info.outputs = for num_ch in [ 0 ... ch.length ]
                    par = ( p for p in parents )
                    par.push info
                    @_update_repr_rec ch[ num_ch ], num_ch, ch.length, par, true
                    
        return info
                
            
    # return true if need rendering after an onchange
    _need_render: ->
        if not @visible[ @visibility_context.get() ]?
            @visible.add_attr @visibility_context.get(), new Lst
            
        for i in [ @closed, @selected, @visible[ @visibility_context.get() ], @visibility_context ]
            if i.has_been_directly_modified()
                return true
        for item in @_flat_item_list()
            if item.has_been_directly_modified()
                return true
            if @get_children_of( item )?.has_been_directly_modified()
                return true
            if @get_output_of( item )?.has_been_directly_modified()
                return true
            if @get_viewable_of( item )?.has_been_directly_modified()
                return true
            if @get_name_class_of( item )?.has_been_modified()
                return true
        return false
    
    _has_a_selected_child: ( item, item_path ) ->
        if @get_children_of( item )?
            for c in @get_children_of( item )
                cp = ( p for p in item_path )
                cp.push c
                if @selected.contains cp
                    return true
                if @_has_a_selected_child c, cp
                    return true
        return false

    _nb_displayed_children: ( info ) ->
        res = 0
        for c in info.children
            res += 1 + @_nb_displayed_children( c )
        return res
        
    _accept_child: ( parent, source ) ->
        return source? and ( source not in parent.parents ) and parent.item.accept_child?( source.item )

    _flat_item_list: ->
        res = []
        for item in @roots
            @_flat_item_list_rec res, item
        return res
        
    _flat_item_list_rec: ( res, item ) ->
        res.push item
        if @get_output_of( item )?
            for c in @get_output_of( item )
                @_flat_item_list_rec res, c
        if @get_children_of( item )?
            for c in @get_children_of( item )
                @_flat_item_list_rec res, c
        
