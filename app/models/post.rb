class Post < ActiveRecord::Base
  has_subscribers
  notifies_subscribers_of :parent, {
    :on => [:update, :create], # new post => draft => publish triggers :update;  new post => publish trigers :create
    :queue_if => lambda{|post| 
      existing_updates = Update.where(:notifier_type => "Post", :notifier_id => post.id)
      # destroy existing updates if user *unpublishes* a post
      if !existing_updates.blank? && post.draft? 
        existing_updates.destroy_all
        return false
      end
      return (post.parent_type == "Project" && !post.draft? && existing_updates.blank?)
    },
    :notification => "created_project_post",
    :include_notifier => true
  }
  belongs_to :parent, :polymorphic => true
  belongs_to :user
  has_many :comments, :as => :parent, :dependent => :destroy
  has_and_belongs_to_many :observations, :uniq => true
  
  validates_length_of :title, :in => 1..2000
  
  before_save :skip_update_for_draft
  after_create :increment_user_counter_cache
  after_destroy :decrement_user_counter_cache
  
  scope :published, where("published_at IS NOT NULL")
  scope :unpublished, where("published_at IS NULL")

  ALLOWED_TAGS = %w(
    a abbr acronym b blockquote br cite code dl dt em embed h1 h2 h3 h4 h5 h6 hr i
    iframe img li object ol p param pre small strong sub sup tt ul
  )

  ALLOWED_ATTRIBUTES = %w(
    href src width height alt cite title class name xml:lang abbr value align
  )
  
  def skip_update_for_draft
    @skip_update = true if draft?
    true
  end
  
  # Update the counter cache in users.
  def increment_user_counter_cache
    self.user.increment!(:journal_posts_count)
    true
  end
  
  def decrement_user_counter_cache
    user.decrement!(:journal_posts_count) if user
    true
  end
  
  def to_s
    "<Post #{self.id}: #{self.to_plain_s}>"
  end
  
  def to_plain_s(options = {})
    s = self.title
    s += ", by #{self.user.login}" unless options[:no_user]
    s
  end
  
  def draft?
    published_at.blank?
  end
end
