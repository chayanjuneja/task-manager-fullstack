from fastapi import FastAPI, Query
from database import engine, SessionLocal
from models import Base, Task
from schemas import TaskCreate
import uuid
from datetime import timedelta

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


# ✅ HELPER (VERY IMPORTANT)
def serialize_task(t):
    return {
        "id": t.id,
        "title": t.title,
        "description": t.description,
        "due_date": t.due_date.isoformat() if t.due_date else None,
        "status": t.status,
        "blocked_by": t.blocked_by,
        "priority": t.priority,
        "recurring": t.recurring,
    }


# ================= CREATE =================
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
            blocked_by=task.blocked_by,
            recurring=task.recurring,
            priority=task.priority
        )

        db.add(new_task)
        db.commit()
        db.refresh(new_task)

        return {
            "data": serialize_task(new_task),
            "message": "Task created"
        }
    finally:
        db.close()


# ================= GET =================
@app.get("/tasks")
def get_tasks(
    search: str = Query(default=None),
    status: str = Query(default=None)
):
    db = SessionLocal()
    try:
        query = db.query(Task)

        if search:
            query = query.filter(Task.title.ilike(f"%{search}%"))

        if status and status != "All":
            query = query.filter(Task.status == status)

        tasks = query.order_by(Task.priority).all()

        return {
            "data": [serialize_task(t) for t in tasks]
        }

    finally:
        db.close()


# ================= UPDATE =================
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
        existing_task.recurring = task.recurring

        # 🔥 RECURRING LOGIC
        if task.status == "Done" and existing_task.recurring != "None":
            new_due = existing_task.due_date

            if existing_task.recurring == "Daily":
                new_due = new_due + timedelta(days=1)
            elif existing_task.recurring == "Weekly":
                new_due = new_due + timedelta(days=7)

            new_task = Task(
                id=str(uuid.uuid4()),
                title=existing_task.title,
                description=existing_task.description,
                due_date=new_due,
                status="To-Do",
                blocked_by=None,
                recurring=existing_task.recurring,
                priority=existing_task.priority + 1
            )

            db.add(new_task)

        db.commit()

        return {"message": "Task updated successfully"}

    finally:
        db.close()


# ================= DELETE =================
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


# ================= REORDER =================
@app.put("/tasks/reorder")
def reorder_tasks(order: list[str]):
    db = SessionLocal()
    try:
        for index, task_id in enumerate(order):
            task = db.query(Task).filter(Task.id == task_id).first()
            if task:
                task.priority = index

        db.commit()
        return {"message": "Order updated"}

    finally:
        db.close()