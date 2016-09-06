defmodule Nimbus do
  def fetch(lat_lon) do
    case System.get_env("forecast_api_key") do
      nil ->
        {:error, "Please set an api key from https://developer.forecast.io/"}
      _ -> {
        lat_lon
          |> get_weather
          |> parse_response
        }
    end
  end

  def set_api_key(new_value) do
    System.put_env("forecast_api_key", new_value)
  end

  def get_weather(lat_lon) do
    HTTPoison.start
    forecast_api_key = System.get_env("forecast_api_key")
    url = "https://api.forecast.io/forecast/" <> forecast_api_key <> "/" <> lat_lon
    HTTPoison.get url
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    data = Poison.decode!(body)
    current =  Map.get(data, "currently")
    temperature =
      current
       |> Map.get("apparentTemperature")
    humidity =
      current
      |> Map.get("humidity")
      |> to_percent
    hourly_summary = data
      |> Map.get("hourly")
      |> Map.get("summary")
      |> String.downcase

    "Currently the temperature is #{temperature}°F with #{humidity} humidity and the weather will be #{hourly_summary}"
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 404}}) do
    IO.puts "No weather data is available for this location"
    System.halt(2)
  end

  defp parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    IO.inspect(reason)
    System.halt(2)
  end

  defp to_percent(number) when is_float(number) do
    percent =
      number * 100
      |> Float.round(2)
      |> Float.to_string
    "#{percent}%"
  end

  defp to_percent(_) do
    "unknown"
  end
end
