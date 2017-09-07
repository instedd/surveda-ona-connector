defmodule SurvedaOnaConnector.Runtime.XLSFormBuilder do
  use GenServer
  import Ecto.Query
  import Ecto
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
      case step["type"] do
        "multiple-choice" ->
          survey = builder.survey
          |> Sheet.set_at(length(builder.survey.rows), 0, "select_one #{step['store']}")
          |> Sheet.set_at(length(builder.survey.rows), 1, step["store"])
          |> Sheet.set_at(length(builder.survey.rows), 2, step["title"])

          #add empty row to choices sheet if not the first choice
          builder = if length(builder.choices.rows) > 1 do
            # builder = %{builder | choices: Sheet.set_at(0, length(builder.choices.rows), "")}
            %{builder | choices: %{builder.choices | rows: builder.choices.rows ++ [[]]}}
          else
           builder
          end

          choices = step["choices"]
          |> Enum.reduce(builder.choices, fn(choice, sheet) ->
            sheet
            |> Sheet.set_at(length(builder.choices.rows), 0, step["store"])
            |> Sheet.set_at(length(builder.choices.rows), 1, choice["response"])
            |> Sheet.set_at(length(builder.choices.rows), 2, choice["response"])
          end)

          %{builder | survey: survey, choices: choices}
        "explanation" ->
          survey = builder.survey
          |> Sheet.set_at(length(builder.survey.rows), 0, "note")
          |> Sheet.set_at(length(builder.survey.rows), 1, step["store"])
          |> Sheet.set_at(length(builder.survey.rows), 2, step["title"])

          %{builder | survey: survey}
        "numeric" ->
          survey = builder.survey
          |> Sheet.set_at(length(builder.survey.rows), 0, "integer")
          |> Sheet.set_at(length(builder.survey.rows), 1, step["store"])
          |> Sheet.set_at(length(builder.survey.rows), 2, step["title"])

          %{builder | survey: survey}
        _ -> builder
      end
    end)
  end

  def build(builder) do
    {:ok, filename} = %Workbook{}
    |> Workbook.append_sheet(builder.survey)
    |> Workbook.append_sheet(builder.choices)
    |> Elixlsx.write_to(builder.filename)
    # |> Elixlsx.write_to("/tmp/#{builder.filename}")
    filename
  end
end
