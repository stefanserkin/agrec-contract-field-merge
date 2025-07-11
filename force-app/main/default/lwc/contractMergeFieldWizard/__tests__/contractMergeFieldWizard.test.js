import { createElement } from '@lwc/engine-dom';
import ContractMergeFieldWizard from 'c/contractMergeFieldWizard';

describe('c-contract-merge-field-wizard', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('TODO: test case generated by CLI command, please fill in test logic', () => {
        // Arrange
        const element = createElement('c-contract-merge-field-wizard', {
            is: ContractMergeFieldWizard
        });

        // Act
        document.body.appendChild(element);

        // Assert
        // const div = element.shadowRoot.querySelector('div');
        expect(1).toBe(1);
    });
});