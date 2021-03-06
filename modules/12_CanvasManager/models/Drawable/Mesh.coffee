# Copyright 2012 Structure Computation  www.structure-computation.com
# Copyright 2012 Hugo Leclerc
#
# This file is part of Soda.
#
# Soda is free software: you can redistribute it and/or modify
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



# This class is use to draw line/dot graph or bar chart
class Mesh extends Drawable
    constructor: ( params = {} ) ->
        super()
       
        

        @add_attr
            _theme : new Theme 
        
            _color_selection: if params.color_selection then true 
        
        @add_attr
            #
            visualization:
                display_style: new Choice( 3, [ "Points", "Wireframe", "Surface", "Surface with Edges" ] )
                point_edition: ( if not params.not_editable then true )
                element_color: @_theme.surfaces.color
                line_color: @_theme.lines.color
            
            # geometry
            points   : []
            _elements: [] # list of Element_Triangle, Element_Line, ...
            
            # helpers
            _selected_points: [] # point refs
            _pelected_points: [] # point refs
        
            _selected_elements: [] # elements refs
            _pelected_elements: [] # elements refs
            
            original_index : []
            
        # default move scheme
        @move_scheme = MoveScheme_3D
        
        # cache
        @_sub_elements = [] # list of { sub_level: , elem_list: , on_skin: , parent }
        @_sub_date = -1
        
        @delete_selected_points_callback = []
        
        
        
    add_point: ( pos = [ 0, 0, 0 ] ) ->
        if not @points[0] then @points.push new TypedArray_Float64 [ 3, 0 ]
        ind = @points[0].size(1) + 1
        @points[0].resize [ 3, ind ]
        @points[0].set_val [ 0, ind-1 ], pos[0]
        @points[0].set_val [ 1, ind-1 ], pos[1]
        @points[0].set_val [ 2, ind-1 ], pos[2]       

    set_point: ( indice, pos = [ 0, 0, 0 ] ) ->
        @points[0].set_val [ 0, indice ], pos[0]
        @points[0].set_val [ 1, indice ], pos[1]
        @points[0].set_val [ 2, indice ], pos[2]  

    get_point: ( indice ) ->
        [ @points[0].get([ 0, indice ]), @points[0].get([ 1, indice ]), @points[0].get([ 2, indice ]) ]


    add_element: ( element ) ->
        @_elements.push element
    
    # get the maximal values or coordinates (absolute)
    bounding_coordinates: () ->
        for i in [ 0 ... @points[0].size(1) ]
            if not bc
                p0 = @get_point i
                bc = [ [ p0[0], p0[0] ], [ p0[1], p0[1] ], [ p0[2], p0[2] ] ]
            else    
                p = @get_point i
                for i in [ 0 .. 2 ]
                    if p[ i ] > bc[ i ][ 0 ]
                        bc[ i ][ 0 ] = p[ i ]
                    else if p[ i ] < bc[ i ][ 1 ]
                        bc[ i ][ 1 ] = p[ i ]
        return bc
    
    nb_points: ->
        @points[0]?.size(1)

    nb_elements: ->
        res = 0
        for el in @_elements
            if typeof el.indices.size( 1 ) == "number"
                res += el.indices.size( 1 )
        res
    
    real_change: ->
        for a in [ @points, @_elements ]
            if a.real_change()
                return true
        false
        
    z_index: ->
        #         if @visualisation.display_field.lst?[ @visualisation.display_field.num.get() ]
        #             return @visualisation.display_field.lst[ @visualisation.display_field.num.get() ].z_index()
        #         else
        return 1000

    clear: ->
        @points.clear()
        @_elements.clear()
    
    add_theme_if_undef: ->
        if not @_theme?
            @add_attr 
                _theme : new Theme 
                
    draw_selected: ( info ) ->    
        @_theme.lines.color.r.set 0
        @_theme.lines.color.b.set 0
        @draw info

    draw_unselected: ( info ) -> 
        @_theme = new Theme
        @draw info

    draw: ( info ) ->
        @add_theme_if_undef()
        if info.ctx_type == 'gl'
            # elements
            for el in @_elements
                el.draw_gl info, this, @points
                
            # draw points if necessary
            draw_points = false
            
            # 2d screen projection
            proj = for i in [ 0 ... @points[0]?.size(1) ]
                info.re_2_sc.proj @get_point(i)
                
#             proj = for p, i in @points[0] when p instanceof Point
#                 console.log p, i
#                 info.re_2_sc.proj p.pos.get()

            if @visualization.point_edition?.get() and info.sel_item[ @model_id ]? # when this is selected and points are editable

            
                # std points
                @_theme.editable_points.beg_ctx info
                for p in proj
                    @_theme.points.draw_proj info, p
                @_theme.editable_points.end_ctx info
                
                # selected points
                if @_selected_points.length
                    @_theme.selected_points.beg_ctx info
                    for p in @_selected_points when p instanceof Point
                        n = info.re_2_sc.proj p.pos.get()
                        @_theme.selected_points.draw_proj info, n
                    @_theme.selected_points.end_ctx info
                
                # preselected points
                if @_pelected_points.length
                    @_theme.highlighted_points.beg_ctx info
                    for p in @_pelected_points when p instanceof Point
                        n = info.re_2_sc.proj p.pos.get()
                        @_theme.highlighted_points.draw_proj info, n
                    @_theme.highlighted_points.end_ctx info
                
            else if @visualization.display_style.equals "Points"
                @_theme.points.beg_ctx info
                for p in proj
                    @_theme.points.draw_proj info, p
                @_theme.points.end_ctx info

                
            # sub elements
            @_update_sub_elements()
            for el in @_sub_elements
                el.draw_gl info, this, @points, true
                
            # selected elements
            if @_selected_elements.length
                for el in @_pelected_points
                    el.draw_gl info, this, @points, true, @_theme.selected_elements
                
            # pre selected elements
            if @_pelected_elements.length
                for el in @_pelected_elements
                    el.draw_gl info, this, @points, true, @_theme.highlighted_elements
             
            return true
    
        # -> 2d canvas
        else if @points?.length
            # 2d screen projection
            proj = for p, i in @points
                info.re_2_sc.proj p.pos.get()

            # elements
            for el in @_elements
                el.draw info, this, proj

            # draw points if necessary
            draw_points = false
            if @visualization.point_edition?.get() and info.sel_item[ @model_id ]? # when this is selected and points are editable
                # std points
                @_theme.editable_points.beg_ctx info
                for p in proj
                    @_theme.points.draw_proj info, p
                @_theme.editable_points.end_ctx info
                
                # selected points
                if @_selected_points.length
                    @_theme.selected_points.beg_ctx info
                    for p in @_selected_points
                        n = info.re_2_sc.proj p.pos.get()
                        @_theme.selected_points.draw_proj info, n
                    @_theme.selected_points.end_ctx info
                
                # preselected points
                if @_pelected_points.length
                    @_theme.highlighted_points.beg_ctx info
                    for p in @_pelected_points
                        n = info.re_2_sc.proj p.pos.get()
                        @_theme.highlighted_points.draw_proj info, n
                    @_theme.highlighted_points.end_ctx info
            
            
            else if @visualization.display_style.equals "Points"
                @_theme.points.beg_ctx info
                for p in proj
                    @_theme.points.draw_proj info, p
                @_theme.points.end_ctx info
                   

            # sub elements
            @_update_sub_elements()
            for el in @_sub_elements
                el.draw info, this, proj, true
                
            # selected elements
            if @_selected_elements.length
                for el in @_pelected_points
                    el.draw info, this, proj, true, @_theme.selected_elements
                
            # pre selected elements
            if @_pelected_elements.length
                for el in @_pelected_elements
                    el.draw info, this, proj, true, @_theme.highlighted_elements
            
    
    on_mouse_down: ( cm, evt, pos, b, old, points_allowed = true ) ->
        delete @_moving_point
        if @visualization.point_edition?.get()
            if b == "LEFT" or b == "RIGHT"
                if points_allowed
                    # preparation
                    proj = for p in @points
                        cm.cam_info.re_2_sc.proj p.pos.get()
                        
                    # closest point with dist < 10
                    best = @_closest_point_closer_than proj, pos, 10
                    if best >= 0
                        if evt.ctrlKey # add / rem selection
                            @_ctrlKey = true
                            if @_selected_points.toggle_ref @points[ best ]
                                @_moving_point = @points[ best ]
                                @_moving_point.beg_click pos
                        else
                            @_ctrlKey = false
                            if not @_selected_points.contains_ref @points[ best ]
                                @_selected_points.clear()
                                @_selected_points.set [ @points[ best ] ]
                            @_moving_point = @points[ best ]
                            @_moving_point.beg_click pos
                            
                        if b == "RIGHT"
                            return false
                        return true
                    else
                        @_selected_points.clear()
                        @_pelected_points.clear()
                        
                    # something with elements ?
                    best = dist: 4
                    for el in @_elements
                        el.closest_point_closer_than? best, this, proj, cm.cam_info, pos
                    for el in @_sub_elements
                        el.closest_point_closer_than? best, this, proj, cm.cam_info, pos
                    if best.disp?
                        # _selected_points
                        np = @points.length
                        ip = @add_point best.disp
                        @_selected_points.clear()
                        @_selected_points.set [ ip ]
                        @_moving_point = ip
                        @_moving_point.beg_click pos
                        
                        # element div
                        res = []
                        divisions = {}
                        for el in @_elements
                            el.cut_with_point? divisions, best, this, np, ip
                            if divisions[ el.model_id ]?
                                for nl in divisions[ el.model_id ]
                                    res.push nl
                            else
                                res.push el
                        @_elements.clear()
                        @_elements.set res
                            
                        
        return false
        
    on_mouse_up_wo_move: ( cm, evt, pos, b, points_allowed = true ) ->
        if @_moving_point? and not @_ctrlKey and @_selected_points.length > 1
            p = @_selected_points.back()
            @_selected_points.clear()
            @_selected_points.set [ p ]
            return true                    
            
    on_mouse_move: ( cm, evt, pos, b, old ) ->
        if @visualization.point_edition?.get()
            # currently moving something ?
            if @_moving_point? and b == "LEFT"
                cm.undo_manager?.snapshot()
                    
                p_0 = cm.cam_info.sc_2_rw.pos pos[ 0 ], pos[ 1 ]
                d_0 = cm.cam_info.sc_2_rw.dir pos[ 0 ], pos[ 1 ]
                @_moving_point.move @_selected_points, @_moving_point.pos, p_0, d_0
                return true

            # preparation
            proj = for p in @points
                cm.cam_info.re_2_sc.proj p.pos.get()
                
            # pre selection of a particular point ?
            best = @_closest_point_closer_than proj, pos, 10
            if best >= 0
                @_pelected_points.clear()
                @_pelected_points.set [ @points[ best ] ]
                return true
                    
            # else, look in element lists
            best = dist: 4
            for el in @_elements
                el.closest_point_closer_than? best, this, proj, cm.cam_info, pos
            for el in @_sub_elements
                el.closest_point_closer_than? best, this, proj, cm.cam_info, pos
            if best.disp?
                @_pelected_points.clear()
                @_pelected_points.set [ new Point best.disp ]
                return true
                
        
        # nothing to pelect :P
        @_pelected_points.clear()
        return false
    
    
    update_min_max: ( x_min, x_max ) ->
        for i in [ 0 ... @points[0]?.size(1) ]
            p = [ @points[0].get([0,i]), @points[0].get([1,i]), @points[0].get([2,i]) ]

            for d in [ 0 ... 3 ]
                x_min[ d ] = Math.min x_min[ d ], p[ d ]
                x_max[ d ] = Math.max x_max[ d ], p[ d ]
    
    make_curve_line_from_selected: ->
        index_selected_points = @_get_indices_of_selected_points()
        if index_selected_points.length
            for sel_point in index_selected_points
                for el in @_elements
                    el.make_curve_line_from_selected sel_point

    break_line_from_selected: ->
        index_selected_points = @_get_indices_of_selected_points()
        if index_selected_points.length
            for sel_point in index_selected_points
                for el in @_elements
                    el.break_line_from_selected sel_point
    
    delete_selected_point: ->
        index_selected_points = @_get_indices_of_selected_points()
           
        if index_selected_points.length > 0
            for ind in [ index_selected_points.length - 1 .. 0 ]
                sel_point = index_selected_points[ ind ]
                p = @points[ sel_point ]
#                 console.log sel_point, p, ind
                
                # old indices -> new indices
                n_array = ( i for i in [ 0 ...  @points.length ] )
                n_array[ sel_point ] = -1
                for j in [ sel_point + 1 ... @points.length ]
                    n_array[ j ] -= 1

                # delete elements containing points
                for el in @_elements
                    el.rem_sub_element? sel_point
                    
                # delete points
                @_selected_points.remove_ref p
                @_pelected_points.remove_ref p
                @points.splice sel_point, 1
                
                for fun in @delete_selected_points_callback
                    fun this, index_selected_points
                    
                #update indices of all following points using new_indices
                done = {}
                for el in @_elements
                    el.update_indices? done, n_array
                
                
    #add "val" to all value in the array started at index "index" (use for ex when a point is deleted)
    _actualise_indices: ( array, val, index = 0 ) ->
        if array.length and val != 0 and index >= 0 and index <= array.length - 1
            for ind in array[ index ... array.length ]
                array[ ind ].set array[ ind ].get() + val
    
    _get_indices_of_selected_points: ->
        index_selected_points = []
        for point, j in @points
            for sel_point in @_selected_points
                if point == sel_point
                    index_selected_points.push j
        return index_selected_points
        
    _update_sub_elements: ->
        if @_sub_date < @_elements._date_last_modification
            @_sub_date = @_elements._date_last_modification
    
            l = ( e for e in @_elements )
            @_sub_elements = []
            while l.length
                oi = @_sub_elements.length
                l.pop().add_sub_element? @_sub_elements
                for n in @_sub_elements[ oi.. ]
                    l.push n
    
    _closest_point_closer_than: ( proj, pos, dist ) ->
        best = -1
        for p, n in proj
            d = Math.sqrt Math.pow( pos[ 0 ] - p[ 0 ], 2 ) + Math.pow( pos[ 1 ] - p[ 1 ], 2 )
            if dist > d
                dist = d
                best = n
        return best
  