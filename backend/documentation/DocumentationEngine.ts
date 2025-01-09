// backend/documentation/DocumentationEngine.ts
import { 
    AIDocGenerator,
    CodeAnalyzer,
    TutorialBuilder,
    InteractiveGuide
} from './modules';

class DocumentationEngine {
    private aiGenerator: AIDocGenerator;
    private codeAnalyzer: CodeAnalyzer;
    private tutorialBuilder: TutorialBuilder;
    private guideBuilder: InteractiveGuide;

    async generateDocumentation(
        codebase: Codebase
    ): Promise<Documentation> {
        // Analyze codebase
        const analysis = await this.codeAnalyzer.analyzeCode(codebase);

        // Generate documentation
        const docs = await this.aiGenerator.generateDocs(analysis);

        // Create tutorials
        const tutorials = await this.tutorialBuilder.createTutorials(analysis);

        // Build interactive guides
        const guides = await this.guideBuilder.createGuides(analysis);

        return {
            documentation: docs,
            tutorials,
            guides,
            searchIndex: await this.createSearchIndex(docs)
        };
    }
}