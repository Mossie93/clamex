defmodule Clamex.Scanner.Clamdscan do
  @moduledoc """
  Scanner implementation for `clamdscan` command-line utility.
  """

  @behaviour Clamex.Scanner

  @doc """
  Perform file scan using `clamdscan` command-line utility.

  ## Examples

      iex> Clamex.Scanner.Clamdscan.scan("test/files/virus.txt")
      {:error, :virus_found}

      iex> Clamex.Scanner.Clamdscan.scan("test/files/safe.txt")
      :ok

  ## Error reasons

  * `:virus_found` - file is infected
  * `:cannot_access_file` - file specified as `path` cannot be accessed
  * `:scanner_not_available` - scanner is not available at `executable_path`
  * `:cannot_connect_to_clamd` - ClamAV daemon is not running in background
  * any other error reported by the scanner will be returned as is (as String)

  """
  @impl true
  @spec scan(path :: Path.t()) ::
          :ok | {:error, atom()} | {:error, String.t()}
  def scan(path, opts \\ []) do
    clamdscan_opts = ["--no-summary" | opts] |> Enum.join(" ")

    try do
      {output, exit_code} =
        System.cmd(
          "clamdscan",
          [clamdscan_opts, path],
          stderr_to_stdout: true
        )

      case exit_code do
        0 -> :ok
        1 -> {:error, :virus_found}
        _ -> {:error, Clamex.Output.extract_error(output)}
      end
    rescue
      error in ErlangError ->
        case error.original do
          :enoent -> {:error, :scanner_not_available}
          _ -> raise error
        end
    end
  end

  def remote_scan(path) do
    scan(path, ["--fdpass", "--stream"])
  end
end
