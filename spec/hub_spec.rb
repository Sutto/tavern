require 'spec_helper'

describe Tavern::Hub do

  let(:hub) { Tavern::Hub.new }

  let(:subscriber_klass) do
    Class.new do

      def published
        @published ||= []
      end

      def call(ctx)
        published << ctx
      end

      def times_called
        published.size
      end

    end
  end

  let(:ctx_from_proc) { [] }

  let(:subscriber_proc) do
    proc { |ctx| ctx_from_proc << ctx }
  end

  describe 'the primary hub' do

    after :each do
      # Force a final reset
      Tavern.hub = nil
    end

    it 'should let you query if something is the primary hub' do
      hub.should respond_to(:primary?)
      hub.should_not be_primary
      Tavern.hub.should_not == hub
      Tavern.hub.should be_primary
    end

    it 'should run the load hook when the hub is changed' do
      Tavern.hub # Force it to have loaded before hand.
      called = 0
      found_hub = nil
      ActiveSupport.on_load(:tavern_hub) do |hub|
        called += 1
        found_hub = hub
      end
      called = 0
      Tavern.hub = hub
      called.should == 1
      found_hub.should == hub
    end

    it 'should unset it when changing the hub' do
      hub = Tavern.hub
      hub.should be_primary
      Tavern.hub = Tavern::Hub.new
      hub.should_not be_primary
    end

    it 'should set it to primary when setting it to the hub value' do
      hub = Tavern::Hub.new
      hub.should_not be_primary
      Tavern.hub = hub
      hub.should be_primary
    end

    it 'always set the default to be primary' do
      # Force a recet to nil
      Tavern.hub = nil
      Tavern.hub.should be_primary
    end

  end

  describe '#subscribe' do

    let(:tracker)  { Struct.new(:called).new(0) }
    let(:callback) { lambda { |e| tracker.called += 1 } }

    it 'should let you subscribe to a top level item' do
      hub.subscribe('x', &callback)
      expect { hub.publish('x') }.to change tracker, :called
      expect { hub.publish('x:y') }.to change tracker, :called
      expect { hub.publish('x:y:z') }.to change tracker, :called
    end

    it 'should let you subscribe to a nested item' do
      hub.subscribe('x:y:z', &callback)
      expect { hub.publish('x:y:z') }.to change tracker, :called
      expect { hub.publish('x:y') }.to_not change tracker, :called
      expect { hub.publish('x') }.to_not change tracker, :called
    end 

    it 'should let you pass an object' do
      callback = Struct.new(:tracker).new(tracker)
      def callback.call(e); tracker.called += 1; end
      hub.subscribe('x', callback)
      expect { hub.publish('x') }.to change tracker, :called
    end

    it 'should let you pass a block' do
      hub.subscribe('x') { |e| tracker.called += 1 }
      expect { hub.publish('x') }.to change tracker, :called
    end

    it 'should return a subscription' do
      subscription = hub.subscribe('x', &callback)
      subscription.should be_present
      subscription.should be_a Tavern::Subscription
    end

    it 'should raise an error when subscribing with an object that does not provide call' do
      expect do
        hub.subscribe 'test', Object.new
      end.to raise_error ArgumentError
    end

  end

  describe '#unsubscribe' do

    let(:tracker) { Struct.new(:count, :calls).new(0, []) }

    let!(:subscription) do
      t = tracker
      hub.subscribe 'test' do |e|
        t.count += 1
        t.calls << e
      end
    end

    it 'should remove an object from the subscription pool' do
      expect { hub.publish 'test' }.to change tracker, :count
      hub.unsubscribe subscription
      expect { hub.publish 'test' }.to_not change tracker, :count
    end

    it 'should return the subscription' do
      hub.unsubscribe(subscription).should == subscription
    end

    it 'should do nothing with a blank item' do
      hub.unsubscribe(nil).should be_nil
      hub.unsubscribe('').should be_nil
    end

  end

  describe '#publish' do

    let(:nested_a)    { subscriber_klass.new }
    let(:nested_b)    { subscriber_klass.new }
    let(:nested_c)    { subscriber_klass.new }
    let(:top_level_a) { subscriber_klass.new }
    let(:top_level_b) { subscriber_klass.new }

    before :each do
      hub.subscribe 'hello',       top_level_a
      hub.subscribe 'hello:world', nested_a
      hub.subscribe 'foo',         top_level_b
      hub.subscribe 'foo:bar',     nested_b
    end

    it 'should add the path parts for a top level call' do
      mock(top_level_a).call(hash_including(:path_parts => %w()))
      hub.publish 'hello', {}
    end

    it 'should add the path parts for a nested call' do
      mock(top_level_a).call(hash_including(:path_parts => %w(world)))
      mock(nested_a).call(hash_including(:path_parts => %w()))
      hub.publish 'hello:world', {}
    end

    it 'should unpack path keys if provided' do
      mock(top_level_a).call(hash_including(:model_name => 'world'))
      mock(nested_a).call(hash_including(:model_name => 'world'))
      hub.publish 'hello:world', :path_keys => [nil, :model_name]
    end

    it 'should add the full path to the publish' do
      mock(top_level_a).call(hash_including(:full_path => 'hello:world'))
      mock(nested_a).call(hash_including(:full_path => 'hello:world'))
      hub.publish 'hello:world', {}
    end

    it 'should notify all subscriptions under the path' do
      expect { hub.publish 'hello:world' }.to change top_level_a, :times_called
      expect { hub.publish 'hello:world' }.to change nested_a, :times_called
      expect { hub.publish 'foo' }.to change top_level_b, :times_called
      expect { hub.publish 'foo' }.to_not change nested_b, :times_called
    end

  end

end
