defmodule SurvedaOnaConnector.Runtime.XLSFormBuilder do
  use GenServer
  import Ecto.Query
  import Ecto
  alias SurvedaOnaConnector.Runtime.XLSFormBuilder
  alias Elixlsx.{Workbook, Sheet}
  defstruct [:name, :survey, :choices]

  def new(filename) do
    survey = %Sheet{name: "survey", rows: [["type", "name", "label", "hint", "required", "constraint", "constraint_message", "relevant", "default", "appearance", "calculation"]]}

    choices = %Sheet{name: "choices", rows: [["list name", "name", "label", "image"]]}

    %XLSFormBuilder{name: filename, survey: survey, choices: choices}
  end

  def add_questionnaire(builder, quiz) do
    quiz["steps"]
    |> Enum.reduce(builder, fn(step, builder) ->
      case step["type"] do
        "multiple-choice" ->
          survey = builder.survey
          |> Sheet.set_at(0, length(builder.survey.rows), "select_one #{step['store']}")
          |> Sheet.set_at(1, length(builder.survey.rows), step["store"])
          |> Sheet.set_at(2, length(builder.survey.rows), step["title"])

          choices = step["choices"]
          |> Enum.reduce(builder.choices, fn(choice, sheet) ->
            sheet
            |> Sheet.set_at(0, length(builder.choices.rows), step["store"])
            |> Sheet.set_at(1, length(builder.choices.rows), choice["response"])
            |> Sheet.set_at(2, length(builder.choices.rows), choice["response"])
          end)

          %{builder | survey: survey, choices: choices}
        "explanation" ->
          survey = builder.survey
          |> Sheet.set_at(0, length(builder.survey.rows), "note")
          |> Sheet.set_at(1, length(builder.survey.rows), step["store"])
          |> Sheet.set_at(2, length(builder.survey.rows), step["title"])

          %{builder | survey: survey}
        "numeric" ->
          survey = builder.survey
          |> Sheet.set_at(0, length(builder.survey.rows), "integer")
          |> Sheet.set_at(1, length(builder.survey.rows), step["store"])
          |> Sheet.set_at(2, length(builder.survey.rows), step["title"])

          %{builder | survey: survey}
        _ -> builder
      end
    end)
  end

  def build(builder) do
    %Workbook{}
    |> Workbook.append_sheet(builder.survey)
    |> Workbook.append_sheet(builder.choices)
    |> Elixlsx.write_to(builder.filename)
  end
end
