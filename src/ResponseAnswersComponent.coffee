React = require 'react'
H = React.DOM
R = React.createElement

formUtils = require './formUtils'
ImageDisplayComponent = require './ImageDisplayComponent'
EntityDisplayComponent = require './EntityDisplayComponent'
AdminRegionDisplayComponent = require './AdminRegionDisplayComponent'
moment = require 'moment'
ezlocalize = require 'ez-localize'

VisibilityCalculator = require './VisibilityCalculator'

# Displays the answers of a response in a table
module.exports = class ResponseAnswersComponent extends React.Component
  @propTypes:
    form: React.PropTypes.object.isRequired
    data: React.PropTypes.object.isRequired
    locale: React.PropTypes.string # Defaults to english

  @contextTypes: 
    getAdminRegionPath: React.PropTypes.func.isRequired # Call with (id, callback). Callback (error, [{ id:, level: <e.g. 1>, name: <e.g. Manitoba>, type: <e.g. Province>}] in level ascending order)
    T: React.PropTypes.func.isRequired  # Localizer to use

  renderLocation: (location) ->
    if location
      return H.div null, 
        H.a onClick: @handleLocationClick.bind(this, location), style: { cursor: "pointer" },
          "#{location.latitude}\u00B0 #{location.longitude}\u00B0"
          if location.accuracy then "(+/-) #{location.accuracy} m"

  renderAnswer: (q, answer) ->
    if not answer
      return null

    # Handle alternates
    if answer.alternate
      switch answer.alternate 
        when "na"
          return H.em null, @context.T("Not Applicable")
        when "dontknow"
          return H.em null, @context.T("Don't Know")

    if not answer.value?
      return null

    switch formUtils.getAnswerType(q)
      when "text", "number"
        return "" + answer.value
      when "choice"
        choice = _.findWhere(q.choices, { id: answer.value })
        if choice
          label = formUtils.localizeString(choice.label, 'en')
          if answer.specify?
            specify = answer.specify[answer.value]
          else
            specify = null

          return H.div null,
            label
            if specify 
              ": "  
              H.em null, specify
        else
          return H.span className: "label label-danger", "Invalid Choice"
      when "choices"
        return _.map answer.value, (v) => 
          choice = _.findWhere(q.choices, { id: v })
          if choice
            return H.div null, 
              formUtils.localizeString(choice.label, 'en')
              if answer.specify? and answer.specify[v]
                ": "
                H.em null, answer.specify[v]
          else 
            return H.div className: "label label-danger", "Invalid Choice"
  
      when "date"
        # Depends on precision
        if answer.value.length <= 7   # YYYY or YYYY-MM
          return H.div null, answer.value
        else if answer.value.length <= 10 # Date
          return H.div null, moment(answer.value).format("LL")
        else
          return H.div null, moment(answer.value).format("LLL")

      when "units"
        if answer.value and answer.value.quantity? and answer.value.units?
          # Find units
          units = _.findWhere(q.units, { id: answer.value.units })

          valueStr = "" + answer.value.quantity
          unitsStr = if units then formUtils.localizeString(units.label, 'en') else "(Invalid)"

          if q.unitsPosition == "prefix" 
            return H.div null,
              H.em null, unitsStr
              " "
              valueStr
          else 
            return H.div null,
              valueStr
              " "
              H.em null, unitsStr

      when "boolean"
        return if answer.value then @context.T("True") else @context.T("False")

      when "location"
        return @renderLocation(answer.value)

      when "image"
        if answer.value
          return R(ImageDisplayComponent, id: answer.value.id)

      when "images"
        return _.map answer.value, (img) =>
          R(ImageDisplayComponent, id: img.id)

      when "texts"
        return _.map answer.value, (txt) =>
          H.div null, txt

      when "site"
        code = answer.value
        # TODO Eventually always go to code parameter. Legacy responses used code directly as value.
        if _.isObject(code)
          code = code.code

        # Convert to new entity type
        siteType = (if q.siteTypes then q.siteTypes[0]) or "Water point" 
        entityType = siteType.toLowerCase().replace(new RegExp(' ', 'g'), "_")

        return R(EntityDisplayComponent, {
          entityCode: code
          entityType: entityType
        })

      when "entity"
        return R(EntityDisplayComponent, {
          entityId: answer.value
          entityType: q.entityType
        })

      when "admin_region"
        return R(AdminRegionDisplayComponent, {
          getAdminRegionPath: @context.getAdminRegionPath
          value: answer.value
        })

  renderQuestion: (q, dataId) ->
    # Get answer
    dataIds = dataId.split('.')
    if dataIds.length == 1
      answer = @props.data[dataId]
    else
      rosterData = @props.data[dataIds[0]]
      answer = rosterData[dataIds[1]].data[dataIds[2]]

    H.tr key: dataId,
      H.td key: "name", style: { width: "50%" },
        formUtils.localizeString(q.text, @props.locale)
      H.td key: "value",
        @renderAnswer(q, answer)
        if answer and answer.timestamp
          H.div null,
            @context.T('Answered')
            ": "
            moment(answer.timestamp).format('llll')
        if answer and answer.location
          @renderLocation(answer.location)

  # Add all the items with the proper rosterId to items array
  # Looks inside groups and sections
  collectItemsReferencingRoster: (items, contents, rosterId) ->
    # Get the contents of all the other question that are referencing this roster
    for otherItem in contents
      if otherItem._type == 'Group' or otherItem._type == 'Section'
        @collectItemsReferencingRoster(items, otherItem.contents, rosterId)
      if otherItem.rosterId == rosterId
        items.push.apply(items, otherItem.contents);

  # dataId is the key used for looking up the data + testing visibility
  # dataId is simply item._id except for rosters children
  renderItem: (item, visibilityStructure, dataId) ->
    if not visibilityStructure[dataId]
      return

    # Sections and Groups behave the same
    if item._type == "Section" or item._type == "Group"
      return [
        H.tr key: item._id,
          H.td colSpan: 2, style: { fontWeight: "bold" },
            formUtils.localizeString(item.name, @props.locale)
        _.map item.contents, (item) =>
          @renderItem(item, visibilityStructure, item._id)
      ]

    # RosterMatrices and RosterGroups behave the same
    # Only the one storing the data will display it
    # The rosters referencing another one will display a simple text to say so
    if item._type == "RosterMatrix" or item._type == "RosterGroup"
      items = []
      # If storing data
      if not item.rosterId?
        items = _.clone item.contents
        # Get the questions of the other rosters referencing this one
        @collectItemsReferencingRoster(items, @props.form.design.contents, item._id)

      return [
        H.tr key: item._id,
          H.td colSpan: 2, style: { fontWeight: "bold" },
            formUtils.localizeString(item.name, @props.locale)
        # Simply display a text referencing the other roster
        if item.rosterId?
          referencedRoster = formUtils.findItem(@props.form.design, item.rosterId)
          H.tr null,
            H.td colSpan: 2,
              H.span style: {fontStyle: 'italic'},
                @context.T("Data is stored in {0}", formUtils.localizeString(referencedRoster.name, @props.locale))
        else
          # Get the data for that roster
          data = @props.data[item._id]
          if data?
            # For each entry in data
            for enty, index in data
              [
                # Display the index of the answer
                H.tr null,
                  H.td colSpan: 2, style: { fontWeight: "bold" },
                    "#{index+1}."
                # And the answer for each question
                _.map items, (childItem) =>
                  dataId = "#{item._id}.#{index}.#{childItem._id}"
                  @renderItem(childItem, visibilityStructure, dataId)
              ]
      ]

    if formUtils.isQuestion(item)
      return @renderQuestion(item, dataId)

  render: ->
    visibilityStructure = new VisibilityCalculator(@props.form.design).createVisibilityStructure(@props.data)

    H.table className: "table table-bordered",
      H.tbody null, 
        _.map @props.form.design.contents, (item) =>
          @renderItem(item, visibilityStructure, item._id)
