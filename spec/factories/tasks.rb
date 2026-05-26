FactoryBot.define do
  factory :task do
    user
    sequence(:title) { |n| "Task #{n}" }
    description { "Task description" }
    status { :todo }
    priority { :medium }
    due_date { 1.week.from_now }

    trait :done do
      status { :done }
      completed_at { Time.current }
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :high_priority do
      priority { :high }
    end

    trait :with_subtasks do
      after(:create) do |task|
        create_list(:task, 2, user: task.user, parent: task, title: "Subtask")
      end
    end

    trait :with_tags do
      after(:create) do |task|
        task.sync_tags!( %w[work urgent] )
      end
    end
  end
end
