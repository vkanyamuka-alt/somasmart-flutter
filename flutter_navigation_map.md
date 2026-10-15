# SomaSmart Flutter — Navigation Map

```mermaid
graph TD
    RootShell[AppShell / TopBar / BottomNavBar] --> Tab0[Home /home]
    RootShell --> Tab1[Shop /shop]
    RootShell --> Tab2[Progress /progress]
    RootShell --> Tab3[Account /account]
    RootShell --> Tab4[Settings /settings]

    RootShell -.-> SideMenu[Side Menu Drawer]
    RootShell -.-> NotifDrawer[Notification & Updates Drawer]
    RootShell -.-> AskMeSheet[Floating Ask Me Chat Sheet]

    Tab3 -->|Quick Access: Subscription| Tab1
    Tab3 -->|Quick Access: Updates| NotifDrawer

    Tab0 -.-> SubDetail[Subject Detail /subjects/:id]
    Tab0 -.-> NoteView[Note Viewer /notes/:id]
    Tab0 -.-> SyllabusLib[Syllabus Library /syllabus]
    Tab0 -.-> QuizExams[Quiz & Exams Hub /quiz-exams]
    QuizExams -.-> QuizSession[Quiz Session /quiz/:id]
    QuizSession -.-> QuizResults[Quiz Results /quiz/results/:attemptId]
    Tab0 -.-> ForumHub[Discussion Forum /forum]
    ForumHub -.-> ForumDetail[Thread Detail /forum/:id]
    Tab0 -.-> AskMeScreen[Ask Me AI Assistant /ask-me]
    FloatingAskMe -.-> AskMeScreen
    Tab1 -.-> SubPlans[Subscription Plans /subscription]
    Tab1 -.-> PaymentCheckout[Payment Checkout /payment]
    SubPlans -.-> PaymentCheckout
```

### Bottom Navigation Tabs (5 canonical mobile destinations):
1. **Home (`/home`)**: Approved homepage (Hero, Active Days, Quick Access Cards, Ask Me shortcut).
2. **Shop (`/shop`)**: Plans, pricing packages, membership status, and book store catalog.
3. **Progress (`/progress`)**: Student study statistics and analytics.
4. **Account (`/account`)**: User profile, editable contact information, verified email, sign out.
5. **Settings (`/settings`)**: Theme, language, notification preferences, terms & policies.

### Deep / Push Routes (Above Shell):
- **Subscription**: `/subscription`
- **Payment Checkout**: `/payment`
- **Subjects**: `/subjects`, `/subjects/:id`
- **Notes**: `/notes/:id`
- **Syllabus**: `/syllabus`
- **Quizzes & Exams**: `/quiz-exams` (with `?tab=topic|exam|practice|timed`), `/exams`
- **Quiz Session**: `/quiz/:id`
- **Quiz Results**: `/quiz/results/:attemptId` (supports `offline` query parameters)
- **Discussion Forum**: `/forum`
- **Thread Detail**: `/forum/:id`
- **Ask Me**: `/ask-me`
