class TimeRange {
    public int MinHour;
    public int MinMinute;
    
    public int MaxHour;
    public int MaxMinute;
}

// Array Indecies
// NOTE(peter): Do we need this?
int MOOD_HAPPY = 0;
int MOOD_PLAY = 1;
int MOOD_SAD = 2;
int MOOD_SLEEP = 3;
int MOOD_DREAM = 4;
int MOOD_SICK = 5;
int MOOD_ANGRY = 6;
int MOOD_PARTY = 7;
int NUM_MOODS = 8;

byte[] MOOD_MASKS = new byte[] {
    (1 << 0), // HAPPY
    (1 << 1), // PLAY
    (1 << 2), // SAD
    (1 << 3), // SLEEP
    (1 << 4), // DREAM
    (1 << 5), // SICK
    (1 << 6), // ANGRY
    (byte)(1 << 7)  // PARTY
};

String[] MOOD_JSON_IDS = new String[] {
    "happy",
    "play",
    "sad",
    "sleep",
    "dream",
    "sick",
    "angry",
    "party"
};

class Project {
    public String Path;
    public TimeRange DisplayTimeRange;
    public byte Moods;
}

List<Project> RegisteredProjects;

TimeRange ParseTimeRange(String minTime, String maxTime)
{
    TimeRange Result = new TimeRange();
    
    // Min Time
    Result.MinHour = Integer.parseInt(minTime.substring(0, 2));
    Result.MinMinute = Integer.parseInt(minTime.substring(3, 5));
    if ('p' == minTime.charAt(5))
        Result.MinHour += 12;
    
    // Max Time
    Result.MaxHour = Integer.parseInt(maxTime.substring(0, 2));
    Result.MaxMinute = Integer.parseInt(maxTime.substring(3, 5));
    if ('p' == maxTime.charAt(5))
        Result.MaxHour += 12;
    
    return Result;
}

byte ParseMoods (JSONArray moods)
{
    byte Result = 0;
    
    int NumMoods = moods.size();
    for (int moodConfig = 0; moodConfig < NumMoods; moodConfig++)
    {
        
        String mood = moods.getString(moodConfig);
        
        for (int moodId = 0; moodId < NUM_MOODS; moodId++)
        {
            if (mood == MOOD_JSON_IDS[moodId])
            {
                Result |= MOOD_MASKS[moodId];
            }
        }
    }
    
    return Result;
}

void InitProjects () 
{
    JSONObject ProjectRepo = loadJSONObject("data/projects.json");
    JSONArray ProjectsConfig = ProjectRepo.getJSONArray("projects");
    int NumProjects = ProjectsConfig.size();
    
    RegisteredProjects = new ArrayList<Project>();
    
    JSONObject CurrentProjectConfig;
    Project NewProject;
    
    for (int i = 0; i < NumProjects; i++)
    {
        CurrentProjectConfig = ProjectsConfig.getJSONObject(i);
        
        NewProject = new Project();
        NewProject.Path = CurrentProjectConfig.getString("path");
        NewProject.DisplayTimeRange = ParseTimeRange(CurrentProjectConfig.getString("minTime"),
                                                     CurrentProjectConfig.getString("maxTime"));
        NewProject.Moods = ParseMoods(CurrentProjectConfig.getJSONArray("moods"));
        
        RegisteredProjects.add(NewProject);
    }
}

void OpenProject (LX _lx, Project _project)
{
    String AbsoluteProjectPath = dataPath("") + "\\projects\\" + _project.Path;
    
    File ProjectFile = new File(AbsoluteProjectPath);
    
    println("Opening " +  AbsoluteProjectPath);
    lx.openProject(ProjectFile);
}

boolean IsValidTimeForProject (Project _project, int _CurrHour, int _CurrMin)
{
    return _project.DisplayTimeRange.MinHour <= _CurrHour && _project.DisplayTimeRange.MinMinute <= _CurrMin &&
        _project.DisplayTimeRange.MaxHour >= _CurrHour && _project.DisplayTimeRange.MaxMinute >= _CurrMin;
}

Project NextProject (LX _lx, int _CurrHour, int _CurrMin, Project _CurrentProject)
{
    int RandomStartIndex = (int)random(0, RegisteredProjects.size());
    
    for (int i = 0; i < RegisteredProjects.size(); i++)
    {
        Project TestProject = RegisteredProjects.get((RandomStartIndex + i) % RegisteredProjects.size());
        
        println("Index " + i + " Project " + TestProject.Path);
        
        if (IsValidTimeForProject(TestProject, _CurrHour, _CurrMin) &&
            (_CurrentProject == null ||
             _CurrentProject.Path != TestProject.Path))
        {
            OpenProject(_lx, TestProject);
            return TestProject;
        }
    }
    
    return null;
}

class ProjectController implements LXLoopTask
{
    private LX lx;
    private Project CurrentProject;
    
    public ProjectController(LX lx)
    {
        InitProjects();
        OpenProject(lx, RegisteredProjects.get(0));
        CurrentProject = RegisteredProjects.get(0);
        
        if (CurrentProject == null)
            println("ERROR: No project set");
    }
    
    // NOTE(peter): If you remove the ProjectController as a loop task,
    // you need to call this when it is added again, otherwise the controller
    // doesn't have a reference to the open scene
    public void Reset ()
    {
        OpenProject(lx, RegisteredProjects.get(0));
        CurrentProject = RegisteredProjects.get(0);
    }
    
    public String GetNextSceneTimeString()
    {
        String Result = "";
        
        int MaxHour = CurrentProject.DisplayTimeRange.MaxHour;
        int MaxMinute = CurrentProject.DisplayTimeRange.MaxMinute;
        String TimeCode = "a";
        
        if (MaxHour > 12)
        {
            MaxHour -= 12;
            TimeCode = "p";
        }
        
        Result = MaxHour + ":" + MaxMinute + TimeCode;
        println(Result);
        
        return Result;
    }
    
    public void loop(double deltaMs)
    {
        int Hour = hour();
        int Min = minute();
        
        // TODO(peter): If it becomes a problem, maybe check here to see
        // if the open scene and the CurrentProjectScene are the same. 
        // Seems unnecessary right now, but it might be a problem
        
        if (!IsValidTimeForProject(CurrentProject,
                                   Hour, Min))
        {
            println("Is Not Valid Time. Finding Next Project");
            CurrentProject = NextProject(lx, Hour, Min, CurrentProject);
        }
    }
}

class UIProjectControllerPanel extends UICollapsibleSection implements LXParameterListener, LX.ProjectListener
{
    ProjectController Controller;
    
    private final BooleanParameter Enabled = (BooleanParameter) 
        new BooleanParameter("Enabled", false)
        .addListener((LXParameterListener)this);
    
    private UILabel NextSceneTime;
    
    public UIProjectControllerPanel(
        UI _UI, 
        float _PanelWidth,
        ProjectController _Controller)
    {
        super(_UI, 0, 0, _PanelWidth, 0);
        Controller = _Controller;
        
        setLayout(UI2dContainer.Layout.VERTICAL);
        setChildMargin(2,0);
        
        setTitle("PROJECT MODULATOR");
        
        new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Enabled")
            .addToContainer(this);
        
        new UIButton(12, UI_PADDING, 16, 16)
            .setParameter(Enabled)
            .addToContainer(this);
        
        new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("Change At")
            .addToContainer(this);
        
        NextSceneTime = (UILabel)
            new UILabel(UI_PADDING, UI_PADDING, 64, 16)
            .setLabel("00:00p")
            .addToContainer(this);
        
    }
    
    void onParameterChanged(LXParameter parameter)
    {
        if (parameter == Enabled)
        {
            println("Enabled: " + Enabled.getValueb());
            if (Enabled.getValueb())
            {
                Controller.Reset();
                lx.engine.addLoopTask((LXLoopTask)Controller);
            }
            else
            {
                lx.engine.removeLoopTask((LXLoopTask)Controller);
            }
        }
    }
    
    void projectChanged(File project, LX.ProjectListener.Change change)
    {
        if (change == LX.ProjectListener.Change.OPEN)
        {
            NextSceneTime.setLabel(Controller.GetNextSceneTimeString());
        }
    }
}