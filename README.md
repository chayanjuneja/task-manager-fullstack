# 🚀 Flodo AI – Task Management App

A full-stack Task Management application built using **Flutter (Frontend)** and **FastAPI (Backend)**.
This project demonstrates clean architecture, responsive UI, state management, and scalable backend design.

---

## 📌 Overview

This application allows users to:

* Create and manage tasks
* Define dependencies between tasks
* Search and filter tasks efficiently
* Reorder tasks with persistent priority
* Handle recurring tasks automatically

---

## 🧠 Tech Stack

### Frontend

* Flutter (Dart)
* Material UI
* Stateful Widgets
* HTTP package

### Backend

* FastAPI (Python)
* SQLAlchemy ORM
* SQLite Database

---

## ⚙️ Features

### ✅ Core Requirements

#### 📋 Task Model

Each task includes:

* Title
* Description
* Due Date
* Status (To-Do / In Progress / Done)
* Blocked By (optional dependency)

---

### 🖥️ UI & Screens

#### Main Screen

* Displays all tasks in a responsive grid layout
* Blocked tasks appear visually distinct (greyed out)

#### Task Modal (Create/Edit)

* Input all required fields
* Supports editing existing tasks

---

### 🔧 Functionality

#### CRUD Operations

* Create Task
* Read Tasks
* Update Task
* Delete Task

---

#### 📝 Draft Saving

* User input is preserved if dialog is closed accidentally

---

#### 🔍 Search (Server-side)

* Case-insensitive search
* Debounced (400ms)
* Matching text highlighted in UI

---

#### 🎯 Filter

* Filter tasks by status (To-Do / In Progress / Done)

---

#### ⏳ Loading Handling

* 2-second delay simulated for create/update
* UI remains responsive
* Prevents double submission

---

## 🌟 Stretch Goals Implemented

### 🔁 Recurring Tasks

* Options: Daily / Weekly
* When marked "Done", a new task is auto-created with updated due date

---

### 🔀 Persistent Drag & Drop

* Tasks can be reordered
* Order is saved in database via `priority`
* Persists across app reloads

---

## 🏗️ Architecture

### Backend

* Layered structure:

  * Routes → Models → Database
* Efficient querying with filtering + sorting
* Safe DB session handling

### Frontend

* Separation of UI & API service layer
* Debounce logic for search optimization
* State managed using StatefulWidgets

---

## 🚀 Setup Instructions

### 🔧 Backend

```bash
cd backend
py -m venv venv
venv\Scripts\activate
pip install fastapi uvicorn sqlalchemy pydantic
py -m uvicorn main:app --reload
```

Backend runs at:

```
http://127.0.0.1:8000
```

---

### 📱 Frontend

```bash
cd task_app
flutter pub get
flutter run
```

---

## 🎥 Demo

https://drive.google.com/file/d/1hPf8rbHohZdmb91TV4KK5nWaWEB-Vjvv/view?usp=sharing

---

## 🤖 AI Usage Report

### Tools Used

* ChatGPT
* Copilot (optional if used)

### Where AI Helped

* Initial project structure
* Debugging Flutter + FastAPI integration
* UI improvements and state handling
* Backend API optimization

### Example Issue Faced

* SQLAlchemy connection pooling timeout
* Fixed by properly closing DB sessions using `try-finally`

---

## 💡 Key Technical Decisions

* **Server-side search** for scalability
* **Debounce implementation** to reduce API calls
* **Priority-based ordering** for persistent drag & drop
* **Recurring logic handled in backend** for consistency

---

## 📌 Future Improvements

* Authentication system
* Real-time updates (WebSockets)
* Better state management (Provider / Riverpod)
* UI animations and transitions

---

## 👨‍💻 Author

Chayan Juneja

---

## ✅ Summary

This project demonstrates:

* Full-stack capability
* Clean architecture
* Strong UI/UX focus
* Real-world problem solving

---
