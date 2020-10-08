require 'shinka/commands/update'

RSpec.describe Shinka::Commands::Update do
  it "executes `update` command successfully" do
    output = StringIO.new
    options = {}
    command = Shinka::Commands::Update.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
