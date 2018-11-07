export common =
    tools:
        '''
        _mm2px = ( / 25.4 * 96)
        _px2mm = (x) -> 1 / mm2px(x)

        mm2px = (x) ->
            _x = {}
            switch typeof x
            | 'object' =>
                for i of x
                    _x[i] = x[i] |> _mm2px
                _x
            |_ =>
                x |> _mm2px
        '''

export scripts =
    'LM 2576': 'to263 <[ Vin Out Gnd Feedback on/off ]>'
    R1206: '''
      # From http://www.resistorguide.com/resistor-sizes-and-packages/
      r1206 =
          a: 1.6mm
          b: 0.9mm
          c: 2mm

      {a, b, c} = r1206

      p1 = pad b, a
      p2 = p1.clone!
          ..position.x += (c + b) |> mm2px

    '''
    'find-test': '''
      # --------------------------------------------------
      # all lib* scripts will be included automatically.
      # --------------------------------------------------
      find-pin "c1", 5
          ..pad.selected = yes


    '''
    lib_to263: '''
      to263 = (pin-labels) ->
          # From: http://www.ti.com/lit/ds/symlink/lm2576.pdf
          dimensions = d =
              H   : 14.17mm
              die : x:8mm     y:10.8mm
              pads: x:2.16mm  y:1.07mm
              pd  : 1.702

          p1 = pad 1, d.die
              ..data.aecad.label = pin-labels.0

          padg = group()
          for index, pin of [1 to 5]
              pad pin, d.pads, padg
                  ..position.y -= index * mm2px d.pd
                  ..data.aecad.label = pin-labels[index]

          padg.position =
              d.H |> mm2px
              p1.bounds.height / 2


    '''
    'proxy-test': '''

      x = pad 1, {x: 10, y: 20}
      y = ComponentProxy x
      y.on-set 'position', (val) ->
          console.log "Doing MITM for position: ", val
          [null, val]
      y.position += [10, 20]

    '''
    lib_ComponentProxy: '''
      class ComponentProxy
          (main) ~>
              if main
                  @main = that
              @__handlers = {}
              for let key of @main
                  type = typeof! @main[key]
                  if type is \\Function
                      @[key] = @main[key]
                  else
                      #console.log "Defining property: #{key}", type
                      Object.defineProperty @, key, do
                          get: ~>
                              @main[key]

                          set: (val) ~>
                              if @__handlers[key]?
                                  [err, res] = @__handlers[key] val
                                  unless err
                                      @main[key] = res
                              else
                                  @main[key] = val

          on-set: (prop, handler) ->
              @__handlers[prop] = handler


      /*
      y = new ComponentProxy new Group
      y.on-set 'position', (val) ->
          console.log "Doing MITM for position: ", val
          [null, val]
      y.position += [10, 10]
      */
    '''
    lib_pads: '''
      # --------------------------------------------------
      # all lib* scripts will be included automatically.
      #
      # This script will also be treated as a library file.
      # --------------------------------------------------


      # Pad
      # -----------------------------------
      # Usage:
      #
      #   .position: Position
      #

      pad = (pin-number, dimensions, parent) ->
          rect = new Rectangle do
              from: [0, 0]
              to: dimensions |> mm2px

          _group = new Group do
              position: rect.center
              parent: parent or g
              data:
                  aecad:
                      pin: pin-number
              applyMatrix: yes

          cu = new Path.Rectangle do
              rectangle: rect
              fillColor: 'purple'
              parent: _group
              stroke-width: 0
              data:
                  aecad:
                      pin: pin-number

          ttip = new PointText do
              point: cu.bounds.center
              content: pin-number
              fill-color: 'white'
              parent: _group
              font-size: 3
              position: cu.bounds.center

          return _group


    '''
    'class-approach-test': '''
      # Footprint is effectively a Group item
      class Footprint
          ->
              # create main container
              @g = new Group do
                  applyMatrix: no
                  data:
                      aecad:
                          type: \\Footprint

              @pads = []

          position: ~
              -> @g.position
              (val) -> @g.position = val

          color: ~
              (val) ->
                  for @pads
                      ..pad.color = val



      class Pad
          (@opts) ->
              dimensions =
                  x: @opts.width
                  y: @opts.height

              rect = new Rectangle do
                  from: [0, 0]
                  to: dimensions |> mm2px

              @g = new Group do
                  position: rect.center
                  parent: @opts.footprint.g
                  data:
                      aecad:
                          pin: opts.pin
                  applyMatrix: yes

              @opts.footprint.pads.push do
                  params: @opts
                  pad: this

              @cu = new Path.Rectangle do
                  rectangle: rect
                  fillColor: 'purple'
                  parent: @g
                  stroke-width: 0

              @ttip = new PointText do
                  point: @cu.bounds.center
                  content: @opts.pin
                  fill-color: 'white'
                  parent: @g
                  font-size: 3
                  position: @cu.bounds.center

          position: ~
              -> @g.position
              (val) -> @g.position = val

          color: ~
              (val) -> @cu.fillColor = val


      fp = new Footprint 'hello'

      pad1 = new Pad {
          pin: 1
          width: 3
          height: 8
          label: \\hello
          footprint: fp
      }
      debugger
      pad2 = new Pad {
          pin: 2
          width: 4
          height: 8
          label: \\there
          footprint: fp
      }

      pad2.position.x = 40
      fp.position.x += 10

      fp.color = 'red'
    '''
