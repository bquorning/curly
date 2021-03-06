module Curly

  # A base class that can be subclassed by concrete presenters.
  #
  # A Curly presenter is responsible for delivering data to templates, in the
  # form of simple strings. Each public instance method on the presenter class
  # can be referenced in a template. When a template is evaluated with a
  # presenter, the referenced methods will be called with no arguments, and
  # the returned strings inserted in place of the references in the template.
  #
  # Note that strings that are not HTML safe will be escaped.
  #
  # A presenter is always instantiated with a context to which it delegates
  # unknown messages, usually an instance of ActionView::Base provided by
  # Rails. See Curly::TemplateHandler for a typical use.
  #
  # Examples
  #
  #   class BlogPresenter < Curly::Presenter
  #     presents :post
  #
  #     def title
  #       @post.title
  #     end
  #
  #     def body
  #       markdown(@post.body)
  #     end
  #
  #     def author
  #       @post.author.full_name
  #     end
  #   end
  #
  #   presenter = BlogPresenter.new(context, post: post)
  #   presenter.author #=> "Jackie Chan"
  #
  class Presenter

    # Initializes the presenter with the given context and options.
    #
    # context - An ActionView::Base context.
    # options - A Hash of options given to the presenter.
    #
    def initialize(context, options = {})
      @_context = context
      self.class.presented_names.each do |name|
        instance_variable_set("@#{name}", options.fetch(name))
      end
    end

    # The key that should be used to cache the view.
    #
    # Unless `#cache_key` returns nil, the result of rendering the template
    # that the presenter supports will be cached. The return value will be
    # part of the final cache key, along with a digest of the template itself.
    #
    # Any object can be used as a cache key, so long as it
    #
    # - is a String,
    # - responds to #cache_key itself, or
    # - is an Array of a Hash whose items themselves fit either of these
    #   criteria.
    #
    # Returns the cache key Object or nil if no caching should be performed.
    def cache_key
      nil
    end

    # The duration that the view should be cached for. Only relevant if
    # `#cache_key` returns a non nil value.
    #
    # If nil, the view will not have an expiration time set.
    #
    # Examples
    #
    #   def cache_duration
    #     10.minutes
    #   end
    #
    # Returns the Fixnum duration of the cache item, in seconds, or nil if no
    #   duration should be set.
    def cache_duration
      nil
    end

    # Whether a method is available to templates rendered with the presenter.
    #
    # Templates can reference "variables", which are simply methods defined on
    # the presenter. By default, only public instance methods can be
    # referenced, and any method defined on Curly::Presenter itself cannot be
    # referenced. This means that methods such as `#cache_key` and #inspect are
    # not available. This is done for safety purposes.
    #
    # This policy can be changed by overriding this method in your presenters.
    #
    # method - The Symbol name of the method.
    #
    # Returns true if the method can be referenced by a template,
    #   false otherwise.
    def method_available?(method)
      self.class.available_methods.include?(method)
    end

    # A list of methods available to templates rendered with the presenter.
    #
    # Returns an Array of Symbol method names.
    def self.available_methods
      public_instance_methods - Curly::Presenter.public_instance_methods
    end

    private

    class_attribute :presented_names
    self.presented_names = [].freeze

    def self.presents(*args)
      self.presented_names += args
    end

    # Delegates private method calls to the current view context.
    #
    # The view context, an instance of ActionView::Base, is set by Rails.
    def method_missing(method, *args, &block)
      @_context.public_send(method, *args, &block)
    end
  end
end
