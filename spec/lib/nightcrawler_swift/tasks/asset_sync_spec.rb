require 'spec_helper'

unless defined?(Rails)
  module Rails
    def self.root; end
  end
end

describe "asset_sync.rake" do
  let :rake do
    Rake.application = Rake::Application.new
  end

  let :load_path do
    [File.expand_path(File.join(File.dirname(__FILE__), "../../../../lib/nightcrawler_swift/tasks"))]
  end

  before do
    rake.rake_require "asset_sync", load_path, []

    Rake::Task.define_task("environment")
    Rake::Task.define_task("assets:precompile")
  end

  describe "nightcrawler_swift:rails:sync" do
    let(:task_name) { "nightcrawler_swift:rails:sync" }
    subject { rake[task_name] }

    before do
      allow(Rails).to receive(:root).and_return(".")
    end

    it "requires environment and assets:precompile" do
      expect(subject.prerequisites).to include "environment"
    end

    it "calls sync with Rails public dir path" do
      expect(NightcrawlerSwift).to receive(:sync).with("./public")
      subject.invoke
    end

    context "when occurs an error" do
      it "exits with code 1" do
        allow(STDERR).to receive(:puts)
        allow(NightcrawlerSwift).to receive(:sync).and_raise(StandardError.new)
        code = "wrong code"

        begin
          subject.invoke
        rescue SystemExit => e
          code = e.status
        end

        expect(code).to eql(1)
      end
    end
  end

  describe "nightcrawler_swift:rails:asset_sync" do
    let(:task_name) { "nightcrawler_swift:rails:asset_sync" }
    subject { rake[task_name] }

    it "calls 'assets:precompile' and 'nightcrawler_swift:rails:sync'" do
      task1 = double("task1", invoke: true)
      task2 = double("task2", invoke: true)

      expect(Rake::Task).to receive(:[]).with("assets:precompile").and_return(task1)
      expect(Rake::Task).to receive(:[]).with("nightcrawler_swift:rails:sync").and_return(task2)
      expect(task1).to receive(:invoke)
      expect(task2).to receive(:invoke)

      subject.invoke
    end
  end
end
