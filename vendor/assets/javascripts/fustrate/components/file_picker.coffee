class Fustrate.Components.FilePicker extends Fustrate.Components.Base
  constructor: (callback) ->
    input = $ '<input type="file">'

    input
      .change ->
        callback input[0].files

        input.remove()
      .click()
