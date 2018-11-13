require! '../../tools/trace-tool': {TraceTool}
require! '../../tools/freehand': {Freehand}
require! '../../tools/move-tool': {MoveTool}
require! '../../tools/select-tool': {SelectTool}
require! '../../tools/lib/selection': {Selection}
require! 'prelude-ls': {min, empty}
require! 'dcs/lib/keypath': {set-keypath, get-keypath}
require! '../../tools/lib': {getAecad}

export init = (pcb) ->
    # tools
    trace-tool = TraceTool.call this, pcb, (new pcb.Layer)
    freehand = Freehand.call this, pcb, (new pcb.Layer)
    move-tool = MoveTool.call this, pcb, (new pcb.Layer)
    select-tool = SelectTool.call(this)

    # workaround for https://github.com/aktos-io/scada.js/issues/170
    @observe \currTool, (tool) ~>
        @fire \changeTool, {}, tool

    selection = new Selection

    handlers =
        fitAll: (ctx) !~>
            for layer in pcb.project.layers
                selection.add layer, {+select}
            #console.log "fit bounds: ", fit
            fit = pcb.get-bounds!
            if fit
                # set center
                pcb.view.center = fit.center

                # set zoom
                if fit.width > 0 and fit.height > 0
                    curr = pcb.view.bounds
                    padding = 0.8
                    pcb.view.zoom *= padding * min(
                        (curr.width / fit.width),
                        (curr.height / fit.height))

                    @update \pcb.view.zoom

        changeTool: (ctx, tool, proceed) ~>
            console.log "Changing tool to: #{tool}"
            switch tool
            | \tr =>
                trace-tool.activate!
                pcb.cursor \cell
            | \fh =>
                freehand.activate!
                pcb.cursor \default
            | \mv =>
                move-tool.activate!
                pcb.cursor \default
            | \sl =>
                select-tool.activate!
                pcb.cursor \default
            proceed?!

        sendTo: (ctx) ->
            pcb.history.commit!
            layer = ctx.component.get \to
            for pcb.selection.selected
                obj = getAecad ..
                if obj
                    obj.set-side layer
                    #obj.send-to-layer layer

                /*
                unless get-keypath .., "data.aecad.name"
                    set-keypath .., 'data.aecad.name', "c_"
                */

        groupSelected: (ctx) ->
            pcb.history.commit!
            g = new pcb.Group pcb.selection.selected
            console.log "Selected items are grouped:", g
            ctx.component.state \done...

        cleanupDrawing: (ctx) !->
            pcb.history.commit!
            i = 0
            for pcb.search!
                if ..item.getClassName?! in <[ Group Layer ]>
                    if empty ..item.[]children
                        console.log "#{..keypath.join('.')} should be deleted. (\##{++i})"
                        ..item.remove!
            pcb.vlog.info "Removed #{i} items. Use Ctrl+Z for undo."

        explode: (ctx) ->
            exploded = pcb.explode {+recursive}, pcb.selection.selected
            # WIP

        saveBounds: (ctx) ->
            bounds = pcb.get-bounds selection.selected
            pcb.ractive.set \lastBounds, bounds
            console.log "last bounds: ", bounds
            PNotify.info do
                text: "Saved last bounds: (x:#{bounds.center.x |> oneDecimal}, y:#{bounds.center.y |> oneDecimal})"
                addClass: 'nonblock'

        moveToCenter: (ctx) ->
            center = pcb.ractive.get \lastBounds .center
            for selection.selected
                ..position.set center

    return handlers
