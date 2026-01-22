import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Settings, Save, Ruler, DollarSign } from "lucide-react";

const Admin = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [profile, setProfile] = useState<any>(null);

  // Default values state
  const [wallThickness, setWallThickness] = useState<string>("200");
  const [wallHeight, setWallHeight] = useState<string>("2400");
  const [canvasScale, setCanvasScale] = useState<string>("standard");
  const [currency, setCurrency] = useState<string>("SEK");

  useEffect(() => {
    checkAuth();
    loadSettings();
  }, []);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      navigate("/auth");
      return;
    }

    // Fetch profile
    const { data: profileData } = await supabase
      .from("profiles")
      .select("*")
      .eq("user_id", session.user.id)
      .single();

    setProfile(profileData);
    setLoading(false);
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    navigate("/");
  };

  const loadSettings = () => {
    // Load from localStorage
    const savedWallThickness = localStorage.getItem("admin_wallThickness");
    const savedWallHeight = localStorage.getItem("admin_wallHeight");
    const savedCanvasScale = localStorage.getItem("admin_canvasScale");
    const savedCurrency = localStorage.getItem("admin_currency");

    if (savedWallThickness) setWallThickness(savedWallThickness);
    if (savedWallHeight) setWallHeight(savedWallHeight);
    if (savedCanvasScale) setCanvasScale(savedCanvasScale);
    if (savedCurrency) setCurrency(savedCurrency);
  };

  const handleSave = () => {
    try {
      // Save to localStorage
      localStorage.setItem("admin_wallThickness", wallThickness);
      localStorage.setItem("admin_wallHeight", wallHeight);
      localStorage.setItem("admin_canvasScale", canvasScale);
      localStorage.setItem("admin_currency", currency);

      toast({
        title: "Standardvärden sparade",
        description: "Dina inställningar har sparats framgångsrikt.",
      });
    } catch (error) {
      toast({
        title: "Fel",
        description: "Kunde inte spara inställningar",
        variant: "destructive",
      });
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <header className="border-b border-border bg-card">
          <div className="container mx-auto px-4 py-4">
            <h1 className="text-xl font-semibold">Renomate</h1>
          </div>
        </header>
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-center h-64">
            <p className="text-muted-foreground">Laddar...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-card sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div 
            className="flex items-center cursor-pointer" 
            onClick={() => navigate("/projects")}
          >
            <Settings className="h-6 w-6 text-primary mr-2" />
            <h1 className="text-xl font-semibold">Admin</h1>
          </div>
          <Button variant="outline" onClick={() => navigate("/projects")}>
            Tillbaka till Projekt
          </Button>
        </div>
      </header>
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <div className="flex items-center gap-3 mb-6">
          <Settings className="h-8 w-8 text-primary" />
          <div>
            <h1 className="text-3xl font-bold">Admin</h1>
            <p className="text-muted-foreground">Hantera systemets standardvärden</p>
          </div>
        </div>

        {/* Standardvärden Section */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Standardvärden
            </CardTitle>
            <CardDescription>
              Konfigurera standardvärden för ritningar och ekonomi
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Canvas & Drawing Settings */}
            <div className="space-y-4">
              <div className="flex items-center gap-2 text-lg font-semibold border-b pb-2">
                <Ruler className="h-5 w-5 text-primary" />
                <h3>Canvas & Ritning</h3>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="wall-thickness">
                    Vägg Tjocklek (mm)
                  </Label>
                  <Input
                    id="wall-thickness"
                    type="number"
                    value={wallThickness}
                    onChange={(e) => setWallThickness(e.target.value)}
                    placeholder="200"
                  />
                  <p className="text-xs text-muted-foreground">
                    Standard tjocklek för nytecknade väggar
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="wall-height">
                    Vägg Höjd (mm)
                  </Label>
                  <Input
                    id="wall-height"
                    type="number"
                    value={wallHeight}
                    onChange={(e) => setWallHeight(e.target.value)}
                    placeholder="2400"
                  />
                  <p className="text-xs text-muted-foreground">
                    Standard höjd för nytecknade väggar
                  </p>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="canvas-scale">
                  Canvas Standard Skala
                </Label>
                <Select value={canvasScale} onValueChange={setCanvasScale}>
                  <SelectTrigger id="canvas-scale">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="architectural">Architectural 1:20</SelectItem>
                    <SelectItem value="detailed">Detailed 1:50</SelectItem>
                    <SelectItem value="standard">Standard 1:100</SelectItem>
                    <SelectItem value="overview">Overview 1:500</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  Standard skala när en ny canvas öppnas
                </p>
              </div>
            </div>

            {/* Currency Settings */}
            <div className="space-y-4">
              <div className="flex items-center gap-2 text-lg font-semibold border-b pb-2">
                <DollarSign className="h-5 w-5 text-primary" />
                <h3>Ekonomi</h3>
              </div>

              <div className="space-y-2">
                <Label htmlFor="currency">
                  Standard Valuta
                </Label>
                <Select value={currency} onValueChange={setCurrency}>
                  <SelectTrigger id="currency">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="SEK">SEK (kr)</SelectItem>
                    <SelectItem value="EUR">EUR (€)</SelectItem>
                    <SelectItem value="USD">USD ($)</SelectItem>
                    <SelectItem value="NOK">NOK (kr)</SelectItem>
                    <SelectItem value="DKK">DKK (kr)</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  Valuta för Tasks och Purchase Orders
                </p>
              </div>
            </div>

            {/* Save Button */}
            <div className="pt-4 border-t">
              <Button onClick={handleSave} className="w-full md:w-auto">
                <Save className="h-4 w-4 mr-2" />
                Spara Standardvärden
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Current Values Display */}
        <Card className="mt-6">
          <CardHeader>
            <CardTitle className="text-sm font-medium">Aktuella Värden</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div>
                <p className="text-muted-foreground">Vägg Tjocklek</p>
                <p className="font-semibold">{wallThickness} mm</p>
              </div>
              <div>
                <p className="text-muted-foreground">Vägg Höjd</p>
                <p className="font-semibold">{wallHeight} mm</p>
              </div>
              <div>
                <p className="text-muted-foreground">Canvas Skala</p>
                <p className="font-semibold">
                  {canvasScale === "architectural" && "1:20"}
                  {canvasScale === "detailed" && "1:50"}
                  {canvasScale === "standard" && "1:100"}
                  {canvasScale === "overview" && "1:500"}
                </p>
              </div>
              <div>
                <p className="text-muted-foreground">Valuta</p>
                <p className="font-semibold">{currency}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Admin;
