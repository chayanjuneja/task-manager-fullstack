from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TaskCreate(BaseModel):
    title: str
    description: str
    due_date: datetime
    status: str
    blocked_by: Optional[str] = None

class TaskResponse(TaskCreate):
    id: str

    class Config:
        from_attributes = True