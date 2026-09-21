defmodule TucupassWeb.ErrorJSONTest do
  use TucupassWeb.ConnCase, async: true

  test "renders 404" do
    assert TucupassWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TucupassWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
