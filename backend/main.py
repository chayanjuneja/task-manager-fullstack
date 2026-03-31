from fastapi import FastAPI
from database import engine, SessionLocal
from models import Base, Task
from schemas import TaskCreate
import uuid
from fastapi import Query
from sqlalchemy import or_

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)


@app.post("/tasks")
def create_task(task: TaskCreate):
    db = SessionLocal()
    try:
        new_task = Task(
            id=str(uuid.uuid4()),
            title=task.title,
            description=task.description,
            due_date=task.due_date,
            status=task.status,
            blocked_by=task.blocked_by
        )

        db.add(new_task)
        db.commit()
        db.refresh(new_task)

        return {"data": new_task, "message": "Task created"}
    finally:
        db.close()

from fastapi import Query
from sqlalchemy import or_

@app.get("/tasks")
def get_tasks(
    search: str = Query(default=None),
    status: str = Query(default=None)
):
    db = SessionLocal()
    try:
        query = db.query(Task)

        # 🔍 SEARCH (case-insensitive)
        if search:
            query = query.filter(Task.title.ilike(f"%{search}%"))

        # 🎯 FILTER
        if status and status != "All":
            query = query.filter(Task.status == status)

        tasks = query.all()

        return {"data": tasks}

    finally:
        db.close()

@app.put("/tasks/{task_id}")
def update_task(task_id: str, task: TaskCreate):
    db = SessionLocal()
    try:
        existing_task = db.query(Task).filter(Task.id == task_id).first()

        if not existing_task:
            return {"message": "Task not found"}

        existing_task.title = task.title
        existing_task.description = task.description
        existing_task.due_date = task.due_date
        existing_task.status = task.status
        existing_task.blocked_by = task.blocked_by

        db.commit()

        return {"message": "Task updated successfully"}

    finally:
        db.close()   # ✅ IMPORTANT


@app.delete("/tasks/{task_id}")
def delete_task(task_id: str):
    db = SessionLocal()
    try:
        task = db.query(Task).filter(Task.id == task_id).first()

        if not task:
            return {"message": "Task not found"}

        db.delete(task)
        db.commit()

        return {"message": "Task deleted successfully"}

    finally:
        db.close()

   