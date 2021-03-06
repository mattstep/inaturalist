require File.expand_path("../../spec_helper", __FILE__)

describe Comment, "creation" do
  it "should increment a counter cache on the parent if the column exists" do
    o = Observation.make!
    c = Comment.make!(:parent => o)
    o.reload
    o.comments_count.should eq(1)
  end
end

describe Comment, "deletion" do
  it "should decrement a counter cache on the parent if the column exists" do
    o = Observation.make!
    c = Comment.make!(:parent => o)
    o.reload
    o.comments_count.should eq(1)
    c.destroy
    o.reload
    o.comments_count.should eq(0)
  end

  it "should delete an associated update" do
    o = Observation.make!
    s = Subscription.make!(:resource => o)
    c = Comment.make(:parent => o)
    without_delay { c.save }
    Update.where(:subscriber_id => s.user_id, :resource_type => 'Observation', :resource_id => o.id).count.should eq(1)
    c.destroy
    o.reload
    Update.where(:subscriber_id => s.user_id, :resource_type => 'Observation', :resource_id => o.id).count.should eq(0)
  end
end
