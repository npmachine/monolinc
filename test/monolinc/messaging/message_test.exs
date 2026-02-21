defmodule Monolinc.Messaging.MessageTest do
  use Monolinc.DataCase

  alias Monolinc.Messaging.Message

  test "changeset requires content" do
    changeset = Message.changeset(%Message{}, %{content: ""})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).content
  end

  test "changeset enforces max length" do
    changeset = Message.changeset(%Message{}, %{content: String.duplicate("a", 2001)})
    refute changeset.valid?
    assert "should be at most 2000 character(s)" in errors_on(changeset).content
  end
end
