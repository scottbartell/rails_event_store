module RailsEventStore
  module RSpec
    class BeEvent
      class KindMatcher
        def initialize(expected)
          @expected = expected
        end

        def matches?(actual)
          @expected === actual
        end
      end

      class DataMatcher
        def initialize(expected, strict:)
          @strict = strict
          @expected = expected
        end

        def matches?(actual)
          return true unless @expected
          matcher = @strict ? ::RSpec::Matchers::BuiltIn::Match : ::RSpec::Matchers::BuiltIn::Include
          matcher.new(@expected).matches?(actual)
        end
      end

      class FailureMessage
        class ExpectedLine
          def initialize(expected_klass, expected_metadata, expected_data)
            @expected_klass    = expected_klass
            @expected_metadata = expected_metadata
            @expected_data     = expected_data
          end

          def to_s
            ["\nexpected: ", @expected_klass, with, metadata, data]
          end

          private

          def with
            " with" if [@expected_data, @expected_metadata].any?
          end

          def data
            [" data: ", @expected_data] if @expected_data
          end

          def metadata
            [" metadata: ", @expected_metadata] if @expected_metadata
          end
        end

        class ActualLine
          def initialize(actual_klass, actual_metadata, actual_data, expected_metadata, expected_data)
            @actual_klass      = actual_klass
            @actual_metadata   = actual_metadata
            @actual_data       = actual_data
            @expected_metadata = expected_metadata
            @expected_data     = expected_data
          end

          def to_s
            ["\n     got: ", @actual_klass, with, metadata, data, "\n"]
          end

          private

          def with
            " with" if [@expected_data, @expected_metadata].any?
          end

          def data
            [" data: ", @actual_data] if @expected_data
          end

          def metadata
            [" metadata: ", @actual_metadata] if @expected_metadata
          end
        end

        class Diff
          def initialize(actual, expected, label, differ:)
            @actual   = actual
            @expected = expected
            @label    = label
            @differ   = differ
          end

          def to_s
            @expected && ["\n#{@label} diff:", @differ.diff_as_string(@actual.to_s, @expected.to_s)]
          end
        end

        def initialize(expected_klass, actual_klass, expected_data, actual_data, expected_metadata, actual_metadata, differ:)
          @expected_klass    = expected_klass
          @actual_klass      = actual_klass
          @expected_data     = expected_data
          @actual_data       = actual_data
          @expected_metadata = expected_metadata
          @actual_metadata   = actual_metadata
          @differ            = differ
        end

        def to_s
          [
            ExpectedLine.new(@expected_klass, @expected_metadata, @expected_data),
            ActualLine.new(@actual_klass, @actual_metadata.to_h, @actual_data, @expected_metadata, @expected_data),
            Diff.new(@actual_metadata.to_h, @expected_metadata, "Metadata", differ: @differ),
            Diff.new(@actual_data, @expected_data, "Data", differ: @differ)
          ].map(&:to_s).join
        end
      end

      include ::RSpec::Matchers::Composable

      def initialize(expected, differ:)
        @differ   = differ
        @expected = expected
      end

      def matches?(actual)
        @actual = actual
        [matches_kind, matches_data, matches_metadata].all?
      end

      def with_data(expected_data)
        @expected_data = expected_data
        self
      end

      def with_metadata(expected_metadata)
        @expected_metadata = expected_metadata
        self
      end

      def failure_message
        FailureMessage.new(@expected, @actual.class, @expected_data, @actual.data, @expected_metadata, @actual.metadata, differ: @differ).to_s
      end

      def failure_message_when_negated
        %Q{
expected: not a kind of #{@expected}
     got: #{@actual.class}
}
      end

      def strict
        @strict = true
        self
      end

      private

      def matches_kind
        KindMatcher.new(@expected).matches?(@actual)
      end

      def matches_data
        DataMatcher.new(@expected_data, strict: @strict).matches?(@actual.data)
      end

      def matches_metadata
        DataMatcher.new(@expected_metadata, strict: @strict).matches?(@actual.metadata.to_h)
      end
    end
  end
end

