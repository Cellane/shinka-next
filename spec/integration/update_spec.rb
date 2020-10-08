RSpec.describe "`shinka update` command", type: :cli do
  it "executes `shinka help update` command successfully" do
    output = `shinka help update`
    expected_output = <<-OUT
Usage:
  shinka update

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
