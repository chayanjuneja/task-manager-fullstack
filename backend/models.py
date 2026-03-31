from sqlalchemy import Column, String, DateTime
from database import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(String, primary_key=True, index=True)
    title = Column(String)
    description = Column(String)
    due_date = Column(DateTime)
    status = Column(String)
    blocked_by = Column(String, nullable=True)