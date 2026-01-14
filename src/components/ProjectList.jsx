import React, { useState } from 'react'
import './ProjectList.css'

function ProjectList({ projects, onCreateProject, onSelectProject, onDeleteProject }) {
  const [showForm, setShowForm] = useState(false)
  const [projectName, setProjectName] = useState('')
  const [projectDescription, setProjectDescription] = useState('')

  const handleSubmit = (e) => {
    e.preventDefault()
    if (projectName.trim()) {
      onCreateProject(projectName.trim(), projectDescription.trim())
      setProjectName('')
      setProjectDescription('')
      setShowForm(false)
    }
  }

  const getCompletedTasksCount = (project) => {
    return project.tasks.filter(task => task.completed).length
  }

  const getTotalTasksCount = (project) => {
    return project.tasks.length
  }

  return (
    <div className="project-list-container">
      <div className="project-list-header">
        <h2>Mina Byggprojekt</h2>
        <button 
          className="btn btn-primary"
          onClick={() => setShowForm(!showForm)}
        >
          {showForm ? 'Avbryt' : '+ Nytt Projekt'}
        </button>
      </div>

      {showForm && (
        <form className="project-form" onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Projektnamn (t.ex. Köksrenovering)"
            value={projectName}
            onChange={(e) => setProjectName(e.target.value)}
            className="form-input"
            required
          />
          <textarea
            placeholder="Beskrivning (valfritt)"
            value={projectDescription}
            onChange={(e) => setProjectDescription(e.target.value)}
            className="form-textarea"
            rows="3"
          />
          <button type="submit" className="btn btn-success">
            Skapa Projekt
          </button>
        </form>
      )}

      {projects.length === 0 ? (
        <div className="empty-state">
          <p>Inga projekt ännu. Skapa ditt första projekt för att komma igång!</p>
        </div>
      ) : (
        <div className="projects-grid">
          {projects.map(project => (
            <div key={project.id} className="project-card">
              <div className="project-card-header">
                <h3>{project.name}</h3>
                <button
                  className="btn-icon"
                  onClick={() => onDeleteProject(project.id)}
                  title="Ta bort projekt"
                >
                  🗑️
                </button>
              </div>
              {project.description && (
                <p className="project-description">{project.description}</p>
              )}
              <div className="project-stats">
                <span>
                  {getCompletedTasksCount(project)} / {getTotalTasksCount(project)} uppgifter klara
                </span>
              </div>
              <button
                className="btn btn-secondary"
                onClick={() => onSelectProject(project)}
              >
                Öppna Projekt →
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default ProjectList
