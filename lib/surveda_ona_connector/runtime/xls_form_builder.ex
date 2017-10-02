defmodule SurvedaOnaConnector.Runtime.XLSFormBuilder do
  use GenServer
  alias SurvedaOnaConnector.Runtime.XLSFormBuilder
  alias Elixlsx.{Workbook, Sheet}
  defstruct [:filename, :survey, :choices]

  def new(filename) do
    survey = %Sheet{name: "survey", rows: [["type", "name", "label", "hint", "required", "constraint", "constraint_message", "relevant", "default", "appearance", "calculation"]]}

    choices = %Sheet{name: "choices", rows: [["list name", "name", "label", "image"]]}

    %XLSFormBuilder{filename: filename, survey: survey, choices: choices}
  end

  def add_questionnaire(builder, quiz) do
    quiz["steps"]
    |> Enum.reduce(builder, fn(step, builder) ->
      if step["store"] && step["store"] != "" do
        case step["type"] do
          "multiple-choice" ->
            title = if step["title"] && step["title"] != "" do
              step["title"]
            else
              step["store"]
            end
            survey = builder.survey
            |> Sheet.set_at(length(builder.survey.rows), 0, "select_one #{step["store"]}")
            |> Sheet.set_at(length(builder.survey.rows), 1, step["store"])
            |> Sheet.set_at(length(builder.survey.rows), 2, title)

            #add empty row to choices sheet if not the first choice
            builder = if length(builder.choices.rows) > 1 do
              %{builder | choices: Sheet.set_at(builder.choices, length(builder.choices.rows), 0, "")}
            else
             builder
            end

            choices = step["choices"]
            |> Enum.reduce(builder.choices, fn(choice, sheet) ->
              sheet
              |> Sheet.set_at(length(sheet.rows), 0, step["store"])
              |> Sheet.set_at(length(sheet.rows), 1, choice["value"])
              |> Sheet.set_at(length(sheet.rows), 2, choice["value"])
            end)

            %{builder | survey: survey, choices: choices}
          "numeric" ->
            title = if step["title"] && step["title"] != "" do
              step["title"]
            else
              step["store"]
            end
            survey = builder.survey
            |> Sheet.set_at(length(builder.survey.rows), 0, "integer")
            |> Sheet.set_at(length(builder.survey.rows), 1, step["store"])
            |> Sheet.set_at(length(builder.survey.rows), 2, title)

            %{builder | survey: survey}
          _ -> builder
        end
      else
        builder
      end
    end)
  end

  def build(builder) do
    {:ok, file} = %Workbook{}
    |> Workbook.append_sheet(builder.survey)
    |> Workbook.append_sheet(builder.choices)
    |> Elixlsx.write_to_memory(builder.filename)
    file
  end
end
