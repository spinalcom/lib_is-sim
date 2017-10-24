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



#
class CanvasManager extends View
    # mandatory params :
    #  - el; placeholder
    #  - items:
    # optionnal params :
    #  - undo_manager
    #  - allow_gl
    #  - want_aspect_ratio
    #  - constrain_zoom
    #  - width
    #  - auto_fit
    #  - class_name
    @ctx_id = -1
    
    constructor: ( params ) ->
        tmp = {}
        # use params
        for key, val of params
          tmp[ key ] = val

        # default values
        dv = ( field, fun ) =>
            if not tmp[ field ]?
                tmp[ field ] = fun()

        dv "items"                , -> new Lst
        dv "cam"                  , => new Cam @want_aspect_ratio
        dv "allow_gl"             , -> false
        dv "theme"                , -> new Theme
        dv "time"                 , -> new ConstrainedVal( 0, { min: 0, max: -1, div: 0 } )
        dv "padding_ratio"        , -> 1.5
        dv "constrain_zoom"       , -> false
        dv "width"                , -> 100
        dv "auto_fit"             , -> false
        dv "class_name"           , -> ''
            
        super [ tmp.items, tmp.cam, tmp.time ]
        for key, val of tmp
          @[key] = val


        #
        @canvas = new_dom_element
            style     : { width: @width + "%" } # , display: "none"
            nodeName  : "canvas"
            className : if @class_name? then @class_name or ''
            parentNode: @el
                

        #touchable events
        #@canvas.Touchable
        #@canvas.touchablemove = ( evt ) => @_mouse_move evt
        #@canvas.tap  = ( evt ) => @_mouse_down evt
        
        
        # events
        @canvas.onmousewheel = ( evt ) => @_mouse_wheel evt
        @canvas.onmousedown  = ( evt ) => @_mouse_down evt
        @canvas.onmousemove  = ( evt ) => @_mouse_move evt
        @canvas.onmouseout   = ( evt ) => @_mouse_out evt
        @canvas.ondblclick   = ( evt ) => @_dbl_click evt
        @canvas.onmouseup    = ( evt ) => @_mouse_up evt
        @canvas.addEventListener? "DOMMouseScroll", @canvas.onmousewheel, false

        # drawing context
        @_init_ctx()
        @x_min = [ 0, 0, 0 ]
        @x_max = [ 1, 1, 1 ]

        #
        @click_fun         = [] # called if mouse down and up without move
        @dblclick_fun      = []
        @select_canvas_fun = [] # call if mousedown or dblclick
        
        # buffers for shaders (unused are immediatly deleted)
        @_buf_list =
            vert:
                buf: {}
                del: ( val ) => @ctx.deleteShader val
            frag:
                buf: {}
                del: ( val ) => @ctx.deleteShader val
            prog:
                buf: {}
                del: ( val ) => @ctx.deleteProgram val

        @fit()
        
    # return a list of items which can take events
    # BEWARE: may be surdefined (as e.g. in CanvasManagerPanelInstance)
    # active items is a list of items which are displayed in the canvas
    active_items: ->
        @items
        
    # selected items is a list of items which are selected in the three
    selected_items: ->
        []
        
    onchange: ->
        if @need_to_redraw()
            @draw()
            
    need_to_redraw: ->
        return true if @items.has_been_directly_modified?()
        return true if @cam.has_been_modified?()
        return true if @theme.has_been_modified?()
        return true if @time.has_been_modified?()

        # if list of active_items has changed (not regarding the objects themselves)
        str_act = ""
        for s in @active_items()
            if not s.has_nothing_to_draw?()
                str_act += " " + s.model_id
        if @_old_str_act != str_act
            @_old_str_act = str_act
            return true

        # if list of active_items has changed (not regarding the objects themselves)
        str_sel = ""
        for s in @selected_items()
            if not s.has_nothing_to_draw?()
                str_sel += " " + s.model_id
        if @_old_str_sel != str_sel
            @_old_str_sel = str_sel
            return true
            
        # all objects and sub objects
        flat = []
        for item in @active_items()
            CanvasManager._get_flat_list flat, item
        for f in flat
            if f.has_been_modified?()
                return true
                
        return false
        
    #
    bounding_box: ->
        if @_bounding_box?
            return @_bounding_box
            
        get_min_max = ( item, x_min, x_max ) ->
            item.update_min_max? x_min, x_max
            if item.sub_canvas_items?
                for sub_item in item.sub_canvas_items()
                    get_min_max sub_item, x_min, x_max
                    
        x_min = [ +1e40, +1e40, +1e40 ]
        x_max = [ -1e40, -1e40, -1e40 ]
        for item in @active_items()
            get_min_max item, x_min, x_max
        if x_min[ 0 ] == +1e40
            return [ [ -1, -1, -1 ], [ 1, 1, 1 ] ]
        @_bounding_box = [ x_min, x_max ]
        return @_bounding_box
        
    # 
    fit: ( anim = 1 ) ->
        b = @bounding_box()

        O = [
            0.5 * ( b[ 1 ][ 0 ] + b[ 0 ][ 0 ] ),
            0.5 * ( b[ 1 ][ 1 ] + b[ 0 ][ 1 ] ), 
            0.5 * ( b[ 1 ][ 2 ] + b[ 0 ][ 2 ] )
        ]
        
        d = @padding_ratio * Math.max(
            ( b[ 1 ][ 0 ] - b[ 0 ][ 0 ] ),
            ( b[ 1 ][ 1 ] - b[ 0 ][ 1 ] ),
            ( b[ 1 ][ 2 ] - b[ 0 ][ 2 ] )
        )
        d = 1 if d == 0
        
        if @cam.r?
            w = @canvas.width
            h = @canvas.height
            
            # assuming a 2D cam
            dx = ( b[ 1 ][ 0 ] - b[ 0 ][ 0 ] )
            dy = ( b[ 1 ][ 1 ] - b[ 0 ][ 1 ] )
            dy = 1 if dy == 0
            ip = 1 / @padding_ratio
            
            if w > h
                rx = ( ip * w ) / ( w - h * ( 1 - ip ) )
                @aset @cam.r, rx * ( h * dx ) / ( w * dy ), anim
                d = dy * @padding_ratio
            else
                ry = ( h - w * ( 1 - ip ) ) / ( ip * h )
                res = ry * ( h * dx ) / ( w * dy )
                @aset @cam.r, res, anim
                d = dx / res * @padding_ratio
    
        @aset @cam.O, O, anim
        @aset @cam.d, d, anim
        @aset @cam.C, @cam.O, anim
    
    # animed set (according to parameters defined in @theme)
    aset: ( model, value, anim = 1 ) ->
        Animation.set model, value, anim * @theme.anim_delay.get()
        
    # 
    top: ->
        @aset @cam.X, [ 1, 0, 0 ]
        @aset @cam.Y, [ 0, 0,-1 ]
    # 
    bottom: ->
        @aset @cam.X, [ 1, 0, 0 ]
        @aset @cam.Y, [ 0, 0, 1 ]
    
    # 
    right: ->
        @aset @cam.X, [ 0, 0,-1 ]
        @aset @cam.Y, [ 0, 1, 0 ]
    
    #
    left: ->
        @aset @cam.X, [ 0, 0, 1 ]
        @aset @cam.Y, [ 0, 1, 0 ]
    
    #
    origin: ->
        @aset @cam.X, [ 1, 0, 0 ]
        @aset @cam.Y, [ 0, 1, 0 ]

    # redraw all the scene
    draw: ->
        @_flat = []
        for item in @active_items()
            CanvasManager._get_flat_list @_flat, item
        
        #
        has_a_background       = false
        has_a_changed_drawable = false
        for f in @_flat
            has_a_background |= f.draws_a_background?()
            has_a_changed_drawable |= f.has_been_modified?()

        # update @cam._O and @cam._d if necessary
        if has_a_changed_drawable
            delete @_bounding_box
            bb = @bounding_box()
            @cam._O.set Vec_3.mus( 0.5, Vec_3.add bb[ 1 ], bb[ 0 ] )
            @cam._d.set Vec_3.len( Vec_3.sub bb[ 1 ], bb[ 0 ] )


        #
                
        if @ctx_type == "gl"
            @ctx.clear @ctx.GL_DEPTH_BUFFER_BIT
        else if not has_a_background
            @ctx.clearRect 0, 0, @canvas.width, @canvas.height
        
        if @sup_canvas_ctx?
            @sup_canvas_ctx.clearRect 0, 0, @sup_canvas.width, @sup_canvas.height
        
        if @auto_fit and has_a_changed_drawable
            if @first_fit?
                @fit 1
            else
                @first_fit = true
                @fit 0

        
        #
        for t, b of @_buf_list
            for n, s of b.buf
                s.used = false
        
        #
        @_mk_cam_info()
        
        # sort object depending on z_index (a greater z_index is in front of an element with a lower z_index)
        @_flat.sort ( a, b ) ->
            if not a.z_index? or not b.z_index?
                console.log a, b
            a.z_index() - b.z_index()
            
        # draw objects
        #dt = (new Date).getTime()
        for item in @_flat
            item.draw @cam_info
        @ctx.finish()
        #console.log (new Date).getTime() - dt,  @sup_canvas_ctx?
            
        # delete unused shaders
        for t, b of @_buf_list
            for n, s of b.buf
                if not s.used
                    b.del s.val
                    delete b.buf[ n ]
        

    resize: ( w, h ) ->
        @canvas.width  = w
        @canvas.height = h
        if @sup_canvas
            @sup_canvas.width  = w
            @sup_canvas.height = h
        if @ctx_type == "gl"
            @ctx.viewport 0, 0, @canvas.width, @canvas.height

    make_sub_canvas: ->
        if not @sup_canvas?
            @sup_canvas = new_dom_element
                style     : 
                    # width: @width + "%"
                    pointerEvents: "none"
                    position: "absolute"
                    zIndex: 1
                    left: 0
                    top: 0
                nodeName  : "canvas"
                className : if @class_name? then @class_name or ''
                parentNode: @el
            @sup_canvas_ctx = @sup_canvas.getContext '2d'
            @sup_canvas.width  = @canvas.width
            @sup_canvas.height = @canvas.height
            

    fillText: ( t, x, y, f = "16pt Arial", a = "center", c = "White" ) ->
        if @ctx_type == "2d"
            @ctx.font = f
            @ctx.textAlign = a
            @ctx.textBaseline = "middle"        
            @ctx.fillText t, x, y
        else
            @make_sub_canvas()
            @sup_canvas_ctx.font = f
            @sup_canvas_ctx.fillStyle = c
            if a == "center-limited"
                m = @sup_canvas_ctx.measureText t
                if x + m.width / 2 + 10 >= @sup_canvas.width
                    x = @sup_canvas.width - 10 - m.width / 2
                @sup_canvas_ctx.textAlign = "center"
            else
                @sup_canvas_ctx.textAlign = a
            @sup_canvas_ctx.textBaseline = "middle"        
            @sup_canvas_ctx.fillText t, x, y
            
            
            #             @sup_canvas_ctx.lineWidth   = 1
            #             @sup_canvas_ctx.strokeStyle = "#993311"
            #             @sup_canvas_ctx.fillStyle = "#553311"
            #             @sup_canvas_ctx.strokeStyle = "#FF0000"
            #             
            #             @sup_canvas_ctx.beginPath()
            #             @sup_canvas_ctx.arc @sup_canvas.width, @sup_canvas.height, 14, 0, Math.PI * 2, true
            #             @sup_canvas_ctx.closePath()
            #             @sup_canvas_ctx.fill()
            #             @sup_canvas_ctx.stroke()
                

    active_items_rec: ( l = @active_items() ) ->
        res = []
        for item in l
            res.push item
            if item.sub_canvas_items?
                for sub_item in @active_items_rec item.sub_canvas_items()
                    res.push sub_item
        res
    
    selected_and_always_active_rec: ->
        res = @selected_items_rec()
        for act in @active_items_rec()
            if act.always_active?()
                res.push act
        return res
    
    selected_items_rec: ( l = @selected_items() ) ->
        res = []
        for item in l
            res.push item
            if item.sub_canvas_items?
                for sub_item in @selected_items_rec item.sub_canvas_items()
                    res.push sub_item
        res

    # get GL vertex shader for src (bufferized)
    gl_vert: ( src ) ->
        @_get_buf_obj "vert", src, =>
            @_make_gl_shader src, @ctx.VERTEX_SHADER

    # get GL fragment shader for src (bufferized)
    gl_frag: ( src ) ->
        @_get_buf_obj "frag", src, =>
            @_make_gl_shader src, @ctx.FRAGMENT_SHADER
        
    # get GL fragment shader for src (bufferized)
    gl_prog: ( vert_src, frag_src ) ->
        vert = @gl_vert vert_src
        frag = @gl_frag frag_src
        src = vert_src + "**" + frag_src
        @_get_buf_obj "prog", src, =>
            @_make_gl_program vert, frag

    #        
    _get_buf_obj: ( list_name, key, fun ) ->
        obj = @_buf_list[ list_name ].buf
        if obj[ key ]?
            obj[ key ].used = true
        else
            obj[ key ] =
                used: true
                val : fun()
        obj[ key ].val

        
    #
    _make_gl_shader: ( src, type ) ->
        shader = @ctx.createShader type
        @ctx.shaderSource shader, src
        @ctx.compileShader shader
        
        if @ctx.getShaderParameter( shader, @ctx.COMPILE_STATUS )
            return shader
        alert "An error occurred compiling the shader: " + src + @ctx.getShaderInfoLog( shader )

    #
    _make_gl_program: ( vert, frag ) ->
        prog = @ctx.createProgram()
        @ctx.attachShader prog, vert
        @ctx.attachShader prog, frag
        @ctx.linkProgram prog
        
        if @ctx.getProgramParameter( prog, @ctx.LINK_STATUS )
            return prog
        alert "Unable to initialize the shader program."
        
        
    # 
    _catch_evt: ( evt ) ->
        evt.preventDefault?()
        evt.returnValue = false
        false
            
    _dbl_click: ( evt ) ->
        for fun in @select_canvas_fun
            fun this, evt
            
        evt = window.event if not evt?
                
        @mouse_x = evt.clientX - get_left( @canvas )
        @mouse_y = evt.clientY - get_top ( @canvas )
        
        for item in @selected_and_always_active_rec()
            if item.on_dbl_click? this, evt, [ @mouse_x, @mouse_y ], @mouse_b
                return @_catch_evt evt
                
        for fun in @dblclick_fun
            if fun this, evt, [ @mouse_x, @mouse_y ], @mouse_b
                return @_catch_evt evt
                
        @_catch_evt evt

    _mouse_down: ( evt ) ->
        @mouse_has_moved_since_mouse_down = false
        
        for fun in @select_canvas_fun
            fun this, evt
        
        evt = window.event if not evt?

        @mouse_b = if evt.which?
            if evt.which < 2
                "LEFT"
            else if evt.which == 2 
                "MIDDLE"
            else
                "RIGHT"
        else
            if evt.button < 2
                "LEFT"
            else if evt.button == 4 
                "MIDDLE"
            else
                "RIGHT"
                
        @mouse_x = evt.clientX - get_left( @canvas )
        @mouse_y = evt.clientY - get_top ( @canvas )
        
        # click_fun from selected items
        for item in @selected_and_always_active_rec()
            if item.on_mouse_down? this, evt, [ @mouse_x, @mouse_y ], @mouse_b
                return @_catch_evt evt

        # else, default click functions
        for fun in @click_fun
            if fun this, evt, [ @mouse_x, @mouse_y ], @mouse_b
                return @_catch_evt evt
            
        # default behavior
        if @mouse_b == "RIGHT"
            @canvas.oncontextmenu = => return false
            evt.stopPropagation()
            evt.cancelBubble = true
            # ... rien ne marche sous chrome sauf document.oncontextmenu = => return false 
            document.oncontextmenu = => return false
            
        @_catch_evt evt        
    
    _mouse_up: ( evt ) ->
        if not @mouse_has_moved_since_mouse_down
            for item in @selected_and_always_active_rec()
                if item.on_mouse_up_wo_move? this, evt, [ @mouse_x, @mouse_y ], @mouse_b
                    delete @mouse_b
                    delete @clk_x
                    delete @clk_y
                    return @_catch_evt evt
                
#         @context_menu? evt, @mouse_b == "RIGHT" and not @mouse_has_moved_since_mouse_down            
        delete @mouse_b
        delete @clk_x
        delete @clk_y

    _mouse_out: ( evt ) ->
        delete @mouse_b
        delete @clk_x
        delete @clk_y
            
    # zoom sur l'objet avec la mollette
    _mouse_wheel: ( evt ) ->
        evt = window.event if not evt?
        @mouse_x = evt.clientX - get_left( @canvas )
        @mouse_y = evt.clientY - get_top ( @canvas )

        # browser compatibility -> stolen from http://unixpapa.com/js/mouse.html
        delta = 0
        if evt.wheelDelta?
            delta = evt.wheelDelta / 120.0
            if window.opera
                delta = - delta
        else if evt.detail
            delta = - evt.detail / 3.0

        # 
        for item in @selected_and_always_active_rec()
            if item.on_mouse_wheel? this, evt, [ @mouse_x, @mouse_y ], @mouse_b, delta
                return @_catch_evt evt

        # do the zoom
        c = Math.pow 1.2, delta
        cx = if evt.shiftKey or @constrain_zoom == "y" then 1 else c
        cy = if evt.altKey   or @constrain_zoom == "x" then 1 else c
        @cam.zoom @mouse_x, @mouse_y, [ cx, cy ], @canvas.width, @canvas.height
        
        @_catch_evt evt        
            
    _mouse_move: ( evt ) ->
        old_x = @mouse_x
        old_y = @mouse_y
    
        evt = window.event if not evt?
        @mouse_has_moved_since_mouse_down = true
        @rea_x = evt.clientX - get_left( @canvas )
        @rea_y = evt.clientY - get_top ( @canvas )
        if evt.ctrlKey and @mouse_b
            if not @clk_x?
                @clk_x = @rea_x
                @clk_y = @rea_y
            @mouse_x = @clk_x + ( @rea_x - @clk_x ) / 10
            @mouse_y = @clk_y + ( @rea_y - @clk_y ) / 10
        else
            @mouse_x = @rea_x
            @mouse_y = @rea_y
        
        # click_fun from selected items
        for item in @selected_and_always_active_rec()
            if item.on_mouse_move? this, evt, [ @mouse_x, @mouse_y ], @mouse_b, [ old_x, old_y ]
                return @_catch_evt evt

        # default behavior (cam change)
        w   = @canvas.width
        h   = @canvas.height
        mwh = Math.min w, h
        
        # rotate / z_screen
        if @mouse_b == "LEFT" and evt.shiftKey
            a = Math.atan2( @mouse_y - 0.5 * h, @mouse_x - 0.5 * w ) - Math.atan2( old_y - 0.5 * h, old_x - 0.5 * w )
            @cam.rotate 0.0, 0.0, a
            return @_catch_evt evt        
            
        # pan
        if @mouse_b == "MIDDLE" or @mouse_b == "RIGHT" or @mouse_b == "LEFT" and evt.ctrlKey
            x = @constrain_zoom != "y"
            y = @constrain_zoom != "x"
            @cam.pan ( @mouse_x - old_x ) * x, ( @mouse_y - old_y ) * y, w, h
            return @_catch_evt evt
            
        if @mouse_b == "LEFT" # rotate / C
            x = 2.0 * ( @mouse_x - old_x ) / mwh
            y = 2.0 * ( @mouse_y - old_y ) / mwh
            @cam.rotate y, x, 0.0
            return @_catch_evt evt
            
        return @_catch_evt evt
            
    # trouve un contexte adequat pour tracer dans le canvas
    _init_ctx: ( opt_attribs ) ->
        # try 3D
        if @allow_gl
            for t in [ "experimental-webgl", "webgl", "webkit-3d", "moz-webgl" ]
                try
                    if @ctx = @canvas.getContext t, opt_attribs
                        @ctx_type = "gl"
                        @ctx.enable @ctx.DEPTH_TEST
                        @ctx.depthFunc @ctx.LESS
                        @ctx.blendFunc @ctx.SRC_ALPHA, @ctx.ONE_MINUS_SRC_ALPHA
                        @ctx.enable @ctx.BLEND
                        @ctx.ctx_id = ( CanvasManager.ctx_id += 1 )
#                         console.log @ctx_type
                        return true
                catch error
                    continue
        # -> 2D
        @ctx_type = "2d"
        @ctx = @canvas.getContext '2d'

    _get_x_min: ->
        @bounding_box()[ 0 ]

    _get_x_max: ->
        @bounding_box()[ 1 ]
        

    # compute and store camera info in @cam_info
    _mk_cam_info: ->
        w = @canvas.width
        h = @canvas.height
        
        i = {}
        for item in @selected_items?()
            CanvasManager._get_items_in_an_hash_table_rec i, item
            
        @cam_info =
            w        : w
            h        : h
            cm       : this
            mwh      : Math.min w, h
            ctx      : @ctx
            cam      : @cam
            ctx_type : @ctx_type
            get_x_min: => @_get_x_min()
            get_x_max: => @_get_x_max()
            re_2_sc  : @cam.re_2_sc w, h
            sc_2_rw  : @cam.sc_2_rw w, h
            sel_item : i
            time     : @time.get()
            time_ref : @time
            theme    : @theme
            padding  : ( 1 - 1 / @padding_ratio ) * Math.min( w, h ) # padding size in pixels
            ctx_2d   : =>
                if @ctx_type == "gl"
                    @make_sub_canvas()
                    @sup_canvas_ctx
                else
                    @ctx
                    
    # get leaves in item list (i.e. object with a draw method)
    @_get_flat_list: ( flat, item ) ->
        if item.sub_canvas_items?
            for sub_item in item.sub_canvas_items()
                CanvasManager._get_flat_list flat, sub_item

        if not item.has_nothing_to_draw?()
            flat.push item

    # fill an hash table with id of selected items
    @_get_items_in_an_hash_table_rec: ( i, item ) ->
        i[ item.model_id ] = true
        if item.sub_canvas_items?
            for n in item.sub_canvas_items()
                CanvasManager._get_items_in_an_hash_table_rec i, n
