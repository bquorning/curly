# Curly is a simple view system. Each view consists of two parts, a
# template and a presenter. The template is a simple string that can contain
# references in the format `{{refname}}`, e.g.
#
#   Hello {{recipient}},
#   you owe us ${{amount}}.
#
# The references will be converted into messages that are sent to the
# presenter, which is any Ruby object. Only public methods can be referenced.
# To continue the earlier example, here's the matching presenter:
#
#   class BankPresenter
#     def initialize(recipient, amount)
#       @recipient, @amount = recipient, amount
#     end
#
#     def recipient
#       @recipient.full_name
#     end
#
#     def amount
#       "%.2f" % @amount
#     end
#   end
#
# See Curly::Presenter for more information on presenters.
#
module Curly
  VERSION = "0.2.1"

  REFERENCE_REGEX = %r(\{\{(\w+)\}\})

  class InvalidReference < StandardError
  end

  class << self

    # Compiles a Curly template to Ruby code.
    #
    # template - The template String that should be compiled.
    #
    # Returns a String containing the Ruby code.
    def compile(template)
      source = template.inspect
      source.gsub!(REFERENCE_REGEX) { compile_reference($1) }

      source
    end

    # Whether the Curly template is valid. This includes whether all
    # references are available on the presenter class.
    #
    # template        - The template String that should be validated.
    # presenter_class - The presenter Class.
    #
    # Returns true if the template is valid, false otherwise.
    def valid?(template, presenter_class)
      references = extract_references(template)
      methods = presenter_class.available_methods.map(&:to_s)
      references & methods == references
    end

    private

    def compile_reference(reference)
      %(\#{
        if presenter.method_available?(:#{reference})
          result = presenter.#{reference} {|*args| yield(*args) }
          ERB::Util.html_escape(result)
        else
          raise Curly::InvalidReference, "invalid reference `{{#{reference}}}'"
        end
      })
    end

    def extract_references(template)
      template.scan(REFERENCE_REGEX).flatten
    end

  end
end

require 'curly/presenter'
require 'curly/template_handler'
require 'curly/railtie' if defined?(Rails)
