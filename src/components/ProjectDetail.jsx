import React, { useState } from 'react'
import './ProjectDetail.css'

function ProjectDetail({ project, onBack, onAddTask, onToggleTask, onDeleteTask }) {
  const [showTaskForm, setShowTaskForm] = useState(false)
  const [taskName, setTaskName] = useState('')
  const [taskDescription, setTaskDescription] = useState('')

  const handleSubmit = (e) => {
    e.preventDefault()
    if (taskName.trim()) {
      onAddTask(project.id, taskName.trim(), taskDescription.trim())
      setTaskName('')
      setTaskDescription('')
      setShowTaskForm(false)
    }
  }

  const completedTasks = project.tasks.filter(task => task.completed).length
  const totalTasks = project.tasks.length
  const progress = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0

  return (
    <div className="project-detail-container">
      <div className="project-detail-header">
        <button className="btn btn-back" onClick={onBack}>
          ← Tillbaka till projekt
        </button>
        <div className="project-info">
          <h2>{project.name}</h2>
          {project.description && (
            <p className="project-description">{project.description}</p>
          )}
        </div>
      </div>

      <div className="progress-section">
        <div className="progress-header">
          <span>Framsteg: {completedTasks} / {totalTasks} uppgifter klara</span>
          <span>{Math.round(progress)}%</span>
        </div>
        <div className="progress-bar">
          <div 
            className="progress-fill" 
            style={{ width: `${progress}%` }}
          ></div>
        </div>
      </div>

      <div className="tasks-section">
        <div className="tasks-header">
          <h3>Uppgifter</h3>
          <button 
            className="btn btn-primary"
            onClick={() => setShowTaskForm(!showTaskForm)}
          >
            {showTaskForm ? 'Avbryt' : '+ Ny Uppgift'}
          </button>
        </div>

        {showTaskForm && (
          <form className="task-form" onSubmit={handleSubmit}>
            <input
              type="text"
              placeholder="Uppgiftsnamn (t.ex. Måla väggar)"
              value={taskName}
              onChange={(e) => setTaskName(e.target.value)}
              className="form-input"
              required
            />
            <textarea
              placeholder="Beskrivning (valfritt)"
              value={taskDescription}
              onChange={(e) => setTaskDescription(e.target.value)}
              className="form-textarea"
              rows="3"
            />
            <button type="submit" className="btn btn-success">
              Lägg till Uppgift
            </button>
          </form>
        )}

        {project.tasks.length === 0 ? (
          <div className="empty-state">
            <p>Inga uppgifter ännu. Lägg till din första uppgift!</p>
          </div>
        ) : (
          <div className="tasks-list">
            {project.tasks.map(task => (
              <div 
                key={task.id} 
                className={`task-item ${task.completed ? 'completed' : ''}`}
              >
                <div className="task-content">
                  <input
                    type="checkbox"
                    checked={task.completed}
                    onChange={() => onToggleTask(project.id, task.id)}
                    className="task-checkbox"
                  />
                  <div className="task-text">
                    <h4>{task.name}</h4>
                    {task.description && (
                      <p>{task.description}</p>
                    )}
                  </div>
                </div>
                <button
                  className="btn-icon"
                  onClick={() => onDeleteTask(project.id, task.id)}
                  title="Ta bort uppgift"
                >
                  🗑️
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default ProjectDetail
