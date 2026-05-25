class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :tasks }
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "todo"
      t.string :priority, null: false, default: "medium"
      t.datetime :due_date
      t.datetime :completed_at
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :tasks, [ :user_id, :parent_id, :position ]
    add_index :tasks, :status
  end
end
